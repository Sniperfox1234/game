extends Node2D
# Shared scaffolding for every playable area (farm, town, cave): tile ground, y-sorted world,
# player, HUD, interaction, fishing, night raids, enemy drops, shop and scene travel.
# Subclasses build their map in _ready, call finish() last, and override _area_process.

const Tiles := preload("res://tiles.gd")
const PLAYER_SCENE := preload("res://player.tscn")
const HudScript := preload("res://hud.gd")
const Quests := preload("res://quests.gd")
const EnemyScript := preload("res://enemy.gd")
const WaterScript := preload("res://water.gd")
const PickupScript := preload("res://pickup.gd")
const AvatarScript := preload("res://avatar.gd")
const UiStyle := preload("res://ui_style.gd")
const Fish := preload("res://fish.gd")
const Cooking := preload("res://cooking.gd")
const InventoryScript := preload("res://inventory.gd")
const SoftShadow := preload("res://soft_shadow.gd")
const FxScript := preload("res://fx.gd")
const AmbientScript := preload("res://ambient_fx.gd")
const TERRAIN_SHADER := preload("res://shaders/terrain.gdshader")
const SWAY_SHADER := preload("res://shaders/sway.gdshader")
# Old tile numbers (as used by the farm and town maps) -> terrain types for the ground shader.
const TILE_TERRAIN := {12: 4, 13: 4, 14: 4, 24: 4, 25: 4, 26: 4, 36: 4, 37: 4, 38: 4, 40: 1, 43: 2}
const InfoMenuScript := preload("res://info_menu.gd")
const PetScript := preload("res://pet.gd")
const PowerupScript := preload("res://powerup.gd")
const Outfits := preload("res://outfits.gd")
const TOWN := preload("res://assets/town/tiles.png")
const DUNGEON := preload("res://assets/dungeon/tiles.png")
const FARM_SCENE := "res://farm.tscn"
const TOWN_SCENE := "res://town.tscn"
const CAVE_SCENE := "res://dungeon.tscn"
const INTERIOR_SCENE := "res://interior.tscn"
const HINT := "Space: act/attack  Shift: dash  I: backpack  F: fireball  Q: potion  E: eat  M: mana"
const BITE_WINDOW := 0.9

enum FishState { NONE, WAIT, BITE }

var map_w := 40
var map_h := 28
var ground := TileMapLayer.new()
var world := Node2D.new()
var player: CharacterBody2D
var hud: CanvasLayer
var canvas_mod := CanvasModulate.new()
var traveling := false
var use_daylight := true
var raids := false

# Things the player can press Space next to. See add_interactable.
var interactables: Array[Dictionary] = []
var pickups: Array[Node2D] = []
var choppables: Array[Dictionary] = []
var pet_node: Node2D
var inventory: CanvasLayer
var terrain_mode := false
var terrain_types := PackedByteArray()
var terrain_rect: ColorRect
var ambient: Node2D
var _sway_materials := {}
var _sun_check := 0.0
var minigame: Node # an overlay mini-game (the shooting gallery) that takes over the keys while active
var pet_entry := {}

var fish_state := FishState.NONE
var fish_timer := 0.0
var fish_pond: Node2D

var raid_timer := 6.0
var _audio_check := 0.0
var was_night := false

var menu: PanelContainer
var menu_fill := Callable()
var menu_home := Vector2(316, 120) # where the menu opens; some rooms move it
var shop_layer := CanvasLayer.new()
var shop_panel := PanelContainer.new()
var shop_info := Label.new()
var shop_buttons := {}
var outfit_panel := PanelContainer.new()
var outfit_info := Label.new()
var outfit_buttons := {} # "hat:crown" / "armor:plate" / "back" -> Button
var outfit_preview := Node2D.new()
var outfit_standalone := false
var outfit_title: Label
const SHOP_TITLES := {"brann": "Brann's Armory", "royal": "The Royal Armoury", "desert": "Zahra's Desert Wares", "harbor": "Salty's Outfitters"}
var outfit_shop := "brann" # which shop is selling: its items show, other shops' items are hidden
var outfit_backdrop := ColorRect.new()


# `terrain` paints the ground with the smooth terrain shader instead of a tile grid.
func begin(tex: Texture2D, terrain := false) -> void:
	if terrain:
		terrain_mode = true
		terrain_types.resize(map_w * map_h)
		terrain_types.fill(0)
		terrain_rect = ColorRect.new()
		terrain_rect.size = Vector2(map_w * 16, map_h * 16)
		terrain_rect.z_index = -10
		terrain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(terrain_rect)
	else:
		ground.tile_set = Tiles.tileset(tex)
		ground.z_index = -10
		add_child(ground)
	world.y_sort_enabled = true
	add_child(world)
	GameState.day_changed.connect(_on_new_day)


func set_terrain(x: int, y: int, type: int) -> void:
	if x >= 0 and y >= 0 and x < map_w and y < map_h:
		terrain_types[y * map_w + x] = type


func set_tile(x: int, y: int, idx: int) -> void:
	if terrain_mode:
		set_terrain(x, y, TILE_TERRAIN.get(idx, 0))
		return
	ground.set_cell(Vector2i(x, y), 0, Vector2i(idx % Tiles.COLS, floori(idx / float(Tiles.COLS))))


func add_blocker(parent: Node2D, rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	parent.add_child(body)
	return body


func spawn_player(pos: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = pos
	world.add_child(player)
	var cam := player.get_node("Camera2D") as Camera2D
	cam.limit_right = map_w * 16
	cam.limit_bottom = map_h * 16
	player.died.connect(_on_player_died)


func _build_terrain() -> void:
	var img := Image.create_empty(map_w, map_h, false, Image.FORMAT_R8)
	for y in map_h:
		for x in map_w:
			img.set_pixel(x, y, Color(terrain_types[y * map_w + x] / 255.0, 0, 0))
	var mat := ShaderMaterial.new()
	mat.shader = TERRAIN_SHADER
	mat.set_shader_parameter("types", ImageTexture.create_from_image(img))
	mat.set_shader_parameter("map_tiles", Vector2i(map_w, map_h))
	terrain_rect.material = mat


# How this place is finished on screen. Areas override to tune it.
func fx_profile() -> Dictionary:
	return {"vignette": 0.30, "shafts": 0.07 if use_daylight else 0.0}


# Which drifting particles to show. Areas override.
func ambient_mode() -> String:
	return ""


# Call last in _ready: adds the lighting layer, HUD and shop panel on top of everything.
func finish(hint: String = HINT) -> void:
	if terrain_mode:
		_build_terrain()
	add_child(canvas_mod)
	FxScript.attach(self, fx_profile())
	ambient = AmbientScript.new()
	player.add_child(ambient)
	hud = HudScript.new()
	hud.hint = hint
	add_child(hud)
	hud.dialogue_changed.connect(func(active: bool): freeze(active))
	_build_shop_panel()
	menu = InfoMenuScript.new()
	shop_layer.add_child(menu)
	inventory = InventoryScript.new()
	inventory.area = self
	add_child(inventory)
	spawn_pet()


func freeze(active: bool) -> void:
	player.set_physics_process(not active)
	if active:
		player.velocity = Vector2.ZERO
		player.get_node("Avatar").call("set_motion", false, false)


func travel(scene: String, spawn: String) -> void:
	if traveling:
		return
	traveling = true
	Audio.sfx("door")
	GameState.next_spawn = spawn
	get_tree().change_scene_to_file(scene)


# ---------- scenery helpers ----------

# A shared wind-sway material. `base` is 0 for a piece on the ground, 1 for one stacked on top.
func sway_material(base: float, strength := 1.3) -> ShaderMaterial:
	var key := "%s_%s" % [base, strength]
	if not _sway_materials.has(key):
		var m := ShaderMaterial.new()
		m.shader = SWAY_SHADER
		m.set_shader_parameter("base", base)
		m.set_shader_parameter("strength", strength)
		_sway_materials[key] = m
	return _sway_materials[key]


func add_tree(tile: Vector2i, kind: int) -> void:
	var tops := [4, 3, 4]
	var bottoms := [16, 15, 16]
	var tree := Node2D.new()
	tree.position = Vector2(tile.x * 16, (tile.y + 1) * 16)
	var top := Tiles.sprite(TOWN, tops[kind], Vector2(0, -32))
	var bottom := Tiles.sprite(TOWN, bottoms[kind], Vector2(0, -16))
	top.material = sway_material(1.0)
	bottom.material = sway_material(0.0)
	SoftShadow.attach(tree, Vector2(26, 10), Vector2(8, -2), 1.0)
	tree.add_child(top)
	tree.add_child(bottom)
	world.add_child(tree)
	add_blocker(tree, Rect2(3, -8, 10, 8))


func add_small_tree(tile: Vector2i, choppable := true) -> void:
	var tree := Node2D.new()
	tree.position = Vector2(tile.x * 16, (tile.y + 1) * 16)
	var crown := Tiles.sprite(TOWN, 28, Vector2(0, -16))
	crown.material = sway_material(0.0, 1.0)
	SoftShadow.attach(tree, Vector2(16, 7), Vector2(8, -2), 0.7)
	tree.add_child(crown)
	world.add_child(tree)
	var body := add_blocker(tree, Rect2(4, -8, 8, 8))
	if not choppable:
		return
	var entry := {"node": tree, "hp": 3, "body": body}
	choppables.append(entry)
	add_interactable(tree, 22.0, func(): _chop(entry), Rect2(), func(): return tree.visible)


func _chop(entry: Dictionary) -> void:
	var tree: Node2D = entry.node
	Audio.sfx("chop", 0.08)
	entry.hp -= 1
	var tw := create_tween()
	tw.tween_property(tree, "rotation", 0.12, 0.05)
	tw.tween_property(tree, "rotation", 0.0, 0.08)
	if entry.hp > 0:
		hud.toast("Chop!")
		return
	var n := randi_range(2, 3)
	GameState.wood += n
	hud.toast("The tree falls! +%d wood (%d)" % [n, GameState.wood])
	tree.visible = false
	(entry.body.get_child(0) as CollisionShape2D).set_deferred("disabled", true)


# A rock you can mine for stone with Space: three hits and it crumbles.
func add_ore(tile: Vector2i, sprite_idx: int) -> void:
	var rock := Node2D.new()
	rock.position = Vector2(tile.x * 16, (tile.y + 1) * 16)
	rock.add_child(Tiles.sprite(DUNGEON, sprite_idx, Vector2(0, -16)))
	world.add_child(rock)
	var body := add_blocker(rock, Rect2(3, -10, 10, 10))
	var entry := {"node": rock, "hp": 3, "body": body}
	add_interactable(rock, 22.0, func(): _mine(entry), Rect2(), func(): return rock.visible)


func _mine(entry: Dictionary) -> void:
	var rock: Node2D = entry.node
	Audio.sfx("mine", 0.1)
	entry.hp -= 1
	GameState.stone += 1
	var tw := create_tween()
	tw.tween_property(rock, "position:x", rock.position.x + 1.5, 0.04)
	tw.tween_property(rock, "position:x", rock.position.x, 0.06)
	if entry.hp > 0:
		hud.toast("Clink! +1 stone (%d)" % GameState.stone)
		return
	hud.toast("The rock crumbles. +1 stone (%d)" % GameState.stone)
	rock.visible = false
	(entry.body.get_child(0) as CollisionShape2D).set_deferred("disabled", true)


# Forest wall around the map edge, leaving out any tree whose tile is inside `gap`.
func build_forest(gap: Rect2i) -> void:
	for x in map_w:
		_tree_unless_gap(Vector2i(x, 1), x % 3, gap)
	for y in range(3, map_h, 2):
		_tree_unless_gap(Vector2i(0, y), y % 3, gap)
		_tree_unless_gap(Vector2i(map_w - 1, y), (y + 1) % 3, gap)
	for x in range(2, map_w - 2, 2):
		_tree_unless_gap(Vector2i(x, map_h - 1), (x + 2) % 3, gap)


func _tree_unless_gap(tile: Vector2i, kind: int, gap: Rect2i) -> void:
	if not gap.has_point(tile):
		add_tree(tile, kind)


# A 4x4 house; `rows` are tile indices (roof, roof, wall, wall). Returns the door position.
func build_house(tile: Vector2i, rows: Array) -> Vector2:
	var base := Node2D.new()
	base.position = Vector2(tile.x * 16, (tile.y + 4) * 16)
	world.add_child(base)
	var width: int = rows[0].size()
	SoftShadow.attach(base, Vector2(width * 16 + 14, 18), Vector2(width * 8, -2), 0.8)
	for r in rows.size():
		for c in width:
			base.add_child(Tiles.sprite(TOWN, rows[r][c], Vector2(c * 16, (r - 4) * 16)))
	add_blocker(base, Rect2(0, -32, width * 16, 32))
	return base.position + Vector2(width * 8, 8)


# A readable signpost standing at `feet`.
func add_sign(feet: Vector2, lines: Variant) -> void:
	var board := Node2D.new()
	board.position = feet
	board.add_child(Tiles.sprite(TOWN, 83, Vector2(-8, -16)))
	world.add_child(board)
	add_blocker(board, Rect2(-5, -8, 10, 8))
	add_interactable(board, 28.0, func(): hud.say("Sign", lines.call() if lines is Callable else lines))


func add_pond(tiles: Rect2i) -> void:
	var pond := Node2D.new()
	pond.set_script(WaterScript)
	pond.size = Vector2(tiles.size) * 16.0
	pond.position = Vector2(tiles.position) * 16.0
	world.add_child(pond)
	add_blocker(pond, Rect2(Vector2(2, 2), pond.size - Vector2(4, 4)))
	add_interactable(pond, 14.0, func(): _start_fishing(pond), Rect2(pond.position, pond.size))


func add_mushroom(tile: Vector2i) -> void:
	var m := Node2D.new()
	m.set_script(PickupScript)
	m.position = Vector2(tile.x * 16, (tile.y + 1) * 16)
	world.add_child(m)
	pickups.append(m)
	add_interactable(m, 22.0, func(): _pick_mushroom(m), Rect2(), Callable(m, "is_available"))


func _pick_mushroom(m: Node2D) -> void:
	m.call("take")
	GameState.mushrooms += 1
	hud.toast("Picked a mushroom! (%d)" % GameState.mushrooms)


# ---------- interaction ----------

# `rect`, if given, makes distance be measured to that world rectangle instead of the node.
# `active`, if given, is called to ask whether the thing can be used right now.
func add_interactable(node: Node2D, reach: float, action: Callable, rect := Rect2(), active := Callable()) -> void:
	interactables.append({"node": node, "reach": reach, "action": action, "rect": rect, "active": active})


func _entry_dist(e: Dictionary, feet: Vector2) -> float:
	var r: Rect2 = e.rect
	if r.size != Vector2.ZERO:
		return feet.distance_to(Vector2(clampf(feet.x, r.position.x, r.end.x), clampf(feet.y, r.position.y, r.end.y)))
	return (e.node as Node2D).global_position.distance_to(feet)


func _interact() -> bool:
	var feet := player.global_position
	var best := {}
	var best_d := INF
	for e in interactables:
		var active: Callable = e.active
		if active.is_valid() and not active.call():
			continue
		var d := _entry_dist(e, feet)
		if d < e.reach and d < best_d:
			best = e
			best_d = d
	if best.is_empty():
		return false
	var action: Callable = best.action
	action.call()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if minigame != null and minigame.get("active"):
		return
	if inventory != null and inventory.active:
		return
	if menu.visible:
		if event.is_action_pressed("ui_cancel"):
			close_menu()
		return
	if outfit_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_outfitter()
		return
	if shop_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			close_shop()
		return
	if hud.busy():
		return
	if fish_state != FishState.NONE:
		if event.is_action_pressed("ui_accept"):
			_fish_press()
		elif event.is_action_pressed("ui_cancel"):
			_end_fishing("You reeled in your line.")
		return
	if event.is_action_pressed("ui_accept"):
		if not _interact():
			player.try_attack()
	elif event.is_action_pressed("attack"):
		player.try_attack()
	elif event.is_action_pressed("inventory"):
		inventory.open()
	elif event.is_action_pressed("fireball"):
		if GameState.spell < 1:
			hud.toast("You haven't learned a spell yet. Merlo's Study in town teaches fireball!")
		elif not player.cast_fireball() and GameState.mp < GameState.FIREBALL_COST:
			hud.toast("Not enough mana! It recharges slowly, or drink a mana potion with M.")
	elif event.is_action_pressed("mana"):
		var got := GameState.drink_mana()
		if got == -2:
			hud.toast("You have no mana potions. Merlo sells them!")
		elif got == -1:
			hud.toast("Your mana is already full.")
		else:
			Audio.sfx("potion")
			hud.toast("Glug! +%d mana" % got)
	elif event.is_action_pressed("eat"):
		var healed := GameState.eat()
		if healed == -2:
			hud.toast("You have nothing to eat. The butcher sells meat!")
		elif healed == -1:
			hud.toast("You're already at full health.")
		else:
			Audio.sfx("eat")
			hud.toast("Yum! +%d HP" % healed)
	elif event.is_action_pressed("potion"):
		if GameState.use_potion():
			player.cure_poison()
			Audio.sfx("potion")
			hud.toast("Glug! +5 HP")
		elif GameState.potions <= 0:
			hud.toast("You have no potions.")
		else:
			hud.toast("You're already at full health.")


# ---------- per-frame ----------

# The track and background ambience for this place. Areas override these.
func music_for() -> String:
	return ""


func ambience_for() -> String:
	return ""


func _process(delta: float) -> void:
	_audio_check -= delta
	if _audio_check <= 0.0:
		_audio_check = 0.5
		Audio.music(music_for())
		Audio.ambience(ambience_for())
		if ambient:
			ambient.call("set_mode", ambient_mode())
	_sun_check -= delta
	if _sun_check <= 0.0:
		_sun_check = 0.3
		_update_sun()
	if use_daylight:
		canvas_mod.color = daylight(GameState.time_of_day)
	_fishing_tick(delta)
	if raids:
		_raid_tick(delta)
	_area_process(delta)


func _area_process(_delta: float) -> void:
	pass


# Points every soft shadow away from the sun (or lights them evenly in places with no sun).
func _update_sun() -> void:
	var s: Array = FxScript.sun(GameState.time_of_day) if use_daylight else [0.0, 1.0, 0.42]
	get_tree().call_group("soft_shadows", "update_sun", s[0], s[1], s[2])


func _on_new_day(_day: int) -> void:
	for p in pickups:
		p.call("regrow")
	for c in choppables:
		c.hp = 3
		c.node.visible = true
		(c.body.get_child(0) as CollisionShape2D).set_deferred("disabled", false)


# ---------- fishing ----------

func _start_fishing(pond: Node2D) -> void:
	fish_pond = pond
	Audio.sfx("cast")
	fish_state = FishState.WAIT
	fish_timer = randf_range(1.5, 3.5)
	freeze(true)
	pond.call("cast", player.global_position)
	hud.toast("Fishing...  Space to reel in, Esc to stop")


func _fishing_tick(delta: float) -> void:
	if fish_state == FishState.NONE:
		return
	fish_timer -= delta
	if fish_timer > 0.0:
		return
	if fish_state == FishState.WAIT:
		fish_state = FishState.BITE
		fish_timer = BITE_WINDOW
		fish_pond.set("bite", true)
		Audio.sfx("bite")
		hud.toast("A bite! Press Space!")
	else:
		_end_fishing("It got away...")


func _fish_press() -> void:
	if fish_state == FishState.WAIT:
		_end_fishing("Too early! You scared the fish.")
		return
	# The faster you react to the bite, the better the fish you can land.
	Audio.sfx("reel")
	var reaction := BITE_WINDOW - fish_timer
	var speed_bonus := clampf(1.0 - reaction / 0.55, 0.0, 1.0)
	var r := randf()
	if r < 0.05:
		Audio.sfx("splash")
		_end_fishing("You reeled in an old boot. Nice.")
	elif r < 0.10:
		GameState.gold += 15
		_end_fishing("You found 15 gold in the mud!")
	else:
		var caught := Fish.roll(speed_bonus + fish_luck, GameState.rod)
		var rarity: String = caught.rarity
		var info: Dictionary = Fish.INFO[rarity]
		var is_new := GameState.record_catch(caught.species, rarity)
		var msg := "Caught a %s %s! Worth %d gold." % [info.name.to_upper() if rarity in ["epic", "legendary"] else info.name, caught.species, info.price]
		if is_new:
			msg += "  New for your fish book!"
		var quest_msg := ""
		if rarity == "epic" or rarity == "legendary":
			quest_msg = Quests.event("epic")
		if quest_msg != "":
			msg += "   |   " + quest_msg
		fish_pond.call("splash", info.color)
		Audio.sfx("splash")
		Audio.sfx("catch_" + rarity)
		_end_fishing(msg, info.color)


func _end_fishing(msg: String, color: Color = UiStyle.CREAM) -> void:
	fish_state = FishState.NONE
	fish_pond.call("reset")
	freeze(false)
	hud.toast(msg, color)


# ---------- monsters ----------

func spawn_enemy(kind: String, pos: Vector2, raider := false) -> Node:
	var e := CharacterBody2D.new()
	e.set_script(EnemyScript)
	e.setup(kind)
	e.raider = raider
	e.position = pos
	e.died.connect(_on_enemy_died)
	e.summon.connect(_on_summon)
	world.add_child(e)
	return e


func _on_summon(kind: String, pos: Vector2) -> void:
	if kind == "orb":
		spawn_powerup(pos)
	elif kind.begins_with("hazard_"):
		var h := Node2D.new()
		h.set_script(load("res://hazard.gd"))
		h.kind = kind.substr(7)
		h.position = pos
		world.add_child(h)
	else:
		spawn_enemy(kind, pos)


# Drops a power-up orb. With no kind given, one is picked at random.
func spawn_powerup(pos: Vector2, kind := "") -> void:
	if kind == "":
		var r := randf()
		kind = "rage" if r < 0.3 else ("swift" if r < 0.6 else ("aegis" if r < 0.85 else "heart"))
	var p := Node2D.new()
	p.set_script(PowerupScript)
	p.kind = kind
	p.area = self
	p.position = pos
	world.add_child(p)


func _on_enemy_died(e: Node) -> void:
	GameState.kills[e.kind] = int(GameState.kills.get(e.kind, 0)) + 1
	var range_: Vector2i = e.gold_range
	var gold := randi_range(range_.x, range_.y)
	GameState.gold += gold
	var msg := "+%d gold" % gold
	if e.boss:
		msg = "The King Slime is defeated! " + msg
	elif GameState.hp < GameState.max_hp and randf() < 0.25:
		GameState.heal(1)
		msg += ", +1 HP"
	if not e.boss and randf() < 0.08:
		GameState.potions += 1
		msg += ", a potion!"
	if not e.boss and randf() < 0.14:
		spawn_powerup(e.position)
	var quest_msg := Quests.on_kill(e.kind, e.raider)
	if quest_msg != "":
		msg += "   |   " + quest_msg
	msg += "   |   +%d XP" % e.xp_value
	if GameState.add_xp(e.xp_value) > 0:
		msg += "   LEVEL UP! You are level %d." % GameState.level
		if GameState.level == GameState.PET_LEVEL:
			msg += " Wren in town can give you a pet!"
	hud.toast(msg)
	_after_enemy_died(e)


# Hook for areas that react to kills (the boss chamber spawns the prize chest here).
func _after_enemy_died(_e: Node) -> void:
	pass


func _on_player_died() -> void:
	GameState.hp = GameState.max_hp
	var lost := int(GameState.gold * 0.1)
	GameState.gold -= lost
	GameState.flags["passed_out"] = lost
	GameState.time_of_day = GameState.MORNING
	travel(FARM_SCENE, "door")


func _is_night() -> bool:
	var t := GameState.time_of_day
	return t > 0.78 or t < 0.2


# At night, slimes and bats attack the farm and the town.
func _raid_tick(delta: float) -> void:
	var night := _is_night()
	if night != was_night:
		was_night = night
		if night:
			Audio.sfx("night")
			hud.toast("Night falls... monsters are coming out!")
		elif not get_tree().get_nodes_in_group("raiders").is_empty():
			Audio.sfx("dawn")
			hud.toast("Dawn breaks. The raiders fled.")
	if not night:
		for r in get_tree().get_nodes_in_group("raiders"):
			r.queue_free()
		raid_timer = 6.0
		return
	raid_timer -= delta
	if raid_timer > 0.0 or hud.busy() or shop_panel.visible or outfit_panel.visible or menu.visible:
		return
	if get_tree().get_nodes_in_group("raiders").size() >= 4:
		return
	raid_timer = randf_range(5.0, 9.0)
	var spot := _free_spot_away(150.0)
	if spot != Vector2.INF:
		spawn_enemy("slime" if randf() < 0.7 else "bat", spot, true)


func _free_spot_away(min_dist: float) -> Vector2:
	var space := get_world_2d().direct_space_state
	for i in 12:
		var p := Vector2(randf_range(40.0, map_w * 16 - 40.0), randf_range(48.0, map_h * 16 - 40.0))
		if p.distance_to(player.global_position) < min_dist:
			continue
		var q := PhysicsPointQueryParameters2D.new()
		q.position = p
		q.collision_mask = 1
		if space.intersect_point(q, 1).is_empty():
			return p
	return Vector2.INF


# ---------- generic menu ----------

# Opens the shared menu. `fill` is called with the menu to (re)populate it whenever it refreshes.
func open_menu(title: String, fill: Callable) -> void:
	menu_fill = fill
	Audio.sfx("open")
	menu.position = menu_home
	menu.setup(title)
	menu.clear()
	fill.call(menu)
	menu.visible = true
	_fit_menu.call_deferred()
	freeze(true)
	menu.focus_button(0)


func refresh_menu() -> void:
	var idx: int = menu.focused_index()
	menu.clear()
	menu_fill.call(menu)
	menu.focus_button(idx)
	_fit_menu.call_deferred()


# Keeps a tall menu on screen by sliding it up if it would run off the bottom.
func _fit_menu() -> void:
	menu.reset_size()
	var y := menu_home.y
	if y + menu.size.y > 636.0:
		y = maxf(8.0, 636.0 - menu.size.y)
	menu.position = Vector2(menu_home.x, y)


func close_menu() -> void:
	Audio.sfx("close")
	menu_home = Vector2(316, 120)
	menu.position = menu_home
	menu.visible = false
	freeze(false)


# ---------- cooking ----------

func open_cooking(title := "Cooking Pot") -> void:
	open_menu(title, _fill_cooking)


func _fill_cooking(m: PanelContainer) -> void:
	var gs := GameState
	m.add_label("You have: %d fish (%d rare+)   %d mushrooms   %d crops   %d meat   %d steak" % [
		gs.fish, gs.fish_at_least("rare"), gs.mushrooms, gs.crops, gs.meat, gs.steak], UiStyle.MUTED, 15)
	if gs.meal_time > 0.0:
		m.add_label("Well fed: %s, %ds left. Cooking something new replaces it." % [gs.meal_data().name, ceili(gs.meal_time)], UiStyle.BORDER, 15)
	for recipe in Cooking.RECIPES:
		var meal: Dictionary = Cooking.MEALS[recipe.meal]
		m.add_button("%s  -  %s\n%s  (%ds)" % [meal.name, Cooking.needs_text(recipe), meal.desc, int(meal.dur)], _cook.bind(recipe), not Cooking.can_cook(recipe))
	m.add_button("Done", close_menu)


func _cook(recipe: Dictionary) -> void:
	if not Cooking.cook(recipe):
		return
	Audio.sfx("sizzle")
	Audio.sfx("cook_done")
	var meal: Dictionary = Cooking.MEALS[recipe.meal]
	var msg := "You cook %s and eat it! %s for %d seconds." % [meal.name, meal.desc, int(meal.dur)]
	var q := Quests.event("cook")
	if q != "":
		msg += "   |   " + q
	hud.toast(msg, UiStyle.BORDER)
	refresh_menu()


# ---------- people and travel (used by the town and every region) ----------

# Where the carriage can take you: scene, fare in gold, and a hint of how tough it is.
const DESTINATIONS := {
	"town": {"name": "Mossbrook", "scene": "res://town.tscn", "fare": 0, "hint": "Home sweet home."},
	"castle": {"name": "Highgarden Castle", "scene": "res://castle.tscn", "fare": 20, "hint": "A safe royal court. Good shops, grand quests."},
	"desert": {"name": "Sunscar Desert", "scene": "res://desert.tscn", "fare": 30, "hint": "Dunes, an oasis and a pyramid tomb. Level 8 or higher."},
	"harbor": {"name": "Port Saltmere", "scene": "res://harbor.tscn", "fare": 30, "hint": "Docks, ocean fishing and a pirate cove. Level 10 or higher."},
	"swamp": {"name": "Mistmere Swamp", "scene": "res://swamp.tscn", "fare": 30, "hint": "Poisonous bog and a witch's lair. Level 12 or higher."},
}
var fish_luck := 0.0 # extra luck when fishing here (the open sea is generous)
var region_id := "" # which DESTINATIONS entry this area is, so the carriage doesn't offer it


func add_npc(id: String, display: String, tile: int, pos: Vector2, wander := 0.0, tint := Color.WHITE, block := true) -> Node2D:
	var npc := Node2D.new()
	npc.set_script(load("res://npc.gd"))
	npc.npc_id = id
	npc.display_name = display
	npc.tile = tile
	npc.position = pos
	npc.wander_r = wander
	npc.tint = tint
	world.add_child(npc)
	if wander == 0.0 and block:
		add_blocker(npc, Rect2(-4, -6, 8, 6))
	return npc


# Says the NPC's quest dialogue (or an idle line), then runs `then` if given.
func say_then(npc: Node2D, then: Callable = Callable()) -> void:
	var t := Quests.talk(npc.npc_id)
	var after: Callable = t.get("after", Callable())
	hud.say(npc.display_name, t.lines, func():
		if after.is_valid():
			var msg: String = after.call()
			if msg != "":
				hud.toast(msg)
		if then.is_valid():
			then.call())


# A villager who simply chats (quest or idle lines) when you press Space.
func add_chatter(id: String, display: String, tile: int, pos: Vector2, wander := 0.0, tint := Color.WHITE) -> Node2D:
	var npc := add_npc(id, display, tile, pos, wander, tint)
	add_interactable(npc, 28.0, func(): say_then(npc))
	return npc


func add_label(text: String, pos: Vector2, color := Color("fff3c4")) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("2e2233"))
	l.add_theme_constant_override("outline_size", 3)
	l.z_index = 30
	world.add_child(l)
	l.position = pos - Vector2(ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x / 2.0 + 2.0, 0)


func add_decor(kind: String, pos: Vector2, size := Vector2.ZERO) -> Node2D:
	var d := Node2D.new()
	d.set_script(load("res://decor.gd"))
	d.kind = kind
	d.position = pos
	if size != Vector2.ZERO:
		d.w = size.x
		d.h = size.y
	world.add_child(d)
	return d


# A horse and wagon with a driver. Talk to him to travel to another place.
func add_carriage(pos: Vector2) -> void:
	var cart := Node2D.new()
	cart.position = pos
	var s := Sprite2D.new()
	s.texture = load("res://pixel_art.gd").carriage()
	s.centered = false
	s.position = Vector2(-38, -37)
	cart.add_child(s)
	world.add_child(cart)
	add_blocker(cart, Rect2(-34, -16, 68, 16))
	SoftShadow.attach(cart, Vector2(76, 12), Vector2(0, -2), 0.5)
	var driver := add_npc("rolf", "Rolf the Driver", 86, pos + Vector2(46, -2), 0.0, Color(0.9, 0.8, 0.6))
	add_interactable(driver, 30.0, func(): say_then(driver, open_travel_menu))
	add_interactable(cart, 40.0, open_travel_menu)


func open_travel_menu() -> void:
	open_menu("Carriage: where to?", _fill_travel)


func _fill_travel(m: PanelContainer) -> void:
	m.add_label("Rolf's carriage takes you anywhere on the king's road. The fare is paid up front.", UiStyle.MUTED, 15)
	for id in DESTINATIONS:
		if id == region_id:
			continue
		var d: Dictionary = DESTINATIONS[id]
		var fare: int = d.fare
		var text := "%s  (%s)" % [d.name, "free" if fare == 0 else "%d gold" % fare]
		m.add_button(text + "\n" + d.hint, _travel_to.bind(id), GameState.gold < fare)
	m.add_button("Stay here", close_menu)


func _travel_to(id: String) -> void:
	var d: Dictionary = DESTINATIONS[id]
	if GameState.gold < d.fare:
		return
	GameState.gold -= d.fare
	close_menu()
	travel(d.scene, "carriage")


# ---------- pet ----------

func spawn_pet() -> void:
	if pet_node:
		interactables.erase(pet_entry)
		pet_node.queue_free()
		pet_node = null
	if GameState.pet == "":
		return
	var p := CharacterBody2D.new()
	p.set_script(PetScript)
	p.kind = GameState.pet
	p.position = player.position + Vector2(-14, 6)
	world.add_child(p)
	pet_node = p
	add_interactable(p, 20.0, func(): p.call("pet_it", hud))
	pet_entry = interactables[interactables.size() - 1]


# ---------- shop ----------

func open_shop() -> void:
	Audio.sfx("open")
	freeze(true)
	_refresh_shop()
	shop_panel.visible = true
	(shop_buttons["seed"] as Button).grab_focus()


func close_shop() -> void:
	Audio.sfx("close")
	shop_panel.visible = false
	freeze(false)


func _build_shop_panel() -> void:
	shop_layer.layer = 3
	add_child(shop_layer)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "Market  (Esc to leave)"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UiStyle.BORDER)
	box.add_child(title)
	shop_info.add_theme_font_size_override("font_size", 16)
	box.add_child(shop_info)
	for entry in [
		["seed", _shop_buy_seed], ["potion", _shop_buy_potion], ["sword", _shop_upgrade_sword],
		["charm", _shop_buy_charm], ["sell", _shop_sell], ["leave", close_shop],
	]:
		var b := Button.new()
		b.pressed.connect(entry[1])
		box.add_child(b)
		shop_buttons[entry[0]] = b
	shop_panel.add_child(box)
	shop_panel.position = Vector2(340, 110)
	shop_panel.custom_minimum_size = Vector2(470, 0)
	shop_panel.visible = false
	shop_panel.theme = UiStyle.menu_theme()
	shop_layer.add_child(shop_panel)
	_build_outfit_panel()


func _build_outfit_panel() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Brann's Armory  (Esc to leave the counter)"
	outfit_title = title
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UiStyle.BORDER)
	box.add_child(title)
	outfit_info.add_theme_font_size_override("font_size", 16)
	box.add_child(outfit_info)
	var hats_label := Label.new()
	hats_label.text = "Hats (just for looks)"
	hats_label.modulate = Color("f2c14e")
	box.add_child(hats_label)
	for id in Outfits.HATS:
		_add_outfit_button(box, "hat:" + id, _on_outfit_pressed.bind("hat", id))
	hats_label.text = "Hats (just for looks)"
	var armor_label := Label.new()
	armor_label.text = "Armor (takes damage off every hit, min 1)"
	armor_label.modulate = Color("f2c14e")
	box.add_child(armor_label)
	for id in Outfits.ARMOR:
		_add_outfit_button(box, "armor:" + id, _on_outfit_pressed.bind("armor", id))
	_add_outfit_button(box, "back", _close_outfitter)
	outfit_panel.add_child(box)
	outfit_panel.position = Vector2(150, 30)
	outfit_panel.custom_minimum_size = Vector2(560, 0)
	outfit_panel.visible = false
	outfit_panel.theme = UiStyle.menu_theme()
	shop_layer.add_child(outfit_panel)

	outfit_backdrop.color = Color(0.1, 0.12, 0.2, 0.85)
	outfit_backdrop.position = Vector2(760, 130)
	outfit_backdrop.size = Vector2(240, 300)
	outfit_backdrop.visible = false
	shop_layer.add_child(outfit_backdrop)
	outfit_preview.set_script(AvatarScript)
	outfit_preview.position = Vector2(880, 390)
	outfit_preview.scale = Vector2(9, 9)
	outfit_preview.visible = false
	shop_layer.add_child(outfit_preview)


func _add_outfit_button(box: VBoxContainer, key: String, action: Callable) -> void:
	var b := Button.new()
	b.pressed.connect(action)
	box.add_child(b)
	outfit_buttons[key] = b


# Opens the hats-and-armor menu. The Armory calls this directly.
func open_outfitter(shop := "brann") -> void:
	outfit_shop = shop
	outfit_title.text = "%s  (Esc to leave the counter)" % SHOP_TITLES.get(shop, "The Armory")
	Audio.sfx("open")
	outfit_standalone = true
	freeze(true)
	shop_panel.visible = false
	outfit_panel.visible = true
	outfit_backdrop.visible = true
	outfit_preview.visible = true
	_refresh_outfits()
	(outfit_buttons["back"] as Button).grab_focus()
	(outfit_buttons["hat:" + str(Outfits.HATS.keys()[0])] as Button).grab_focus()


func _close_outfitter() -> void:
	outfit_panel.visible = false
	outfit_backdrop.visible = false
	outfit_preview.visible = false
	if outfit_standalone:
		outfit_standalone = false
		freeze(false)
		return
	shop_panel.visible = true
	_refresh_shop()
	(shop_buttons["seed"] as Button).grab_focus()


func _on_outfit_pressed(kind: String, id: String) -> void:
	var err := GameState.toggle_hat(id) if kind == "hat" else GameState.toggle_armor(id)
	if err != "":
		hud.toast(err)
	_refresh_outfits()


func _outfit_label(name_: String, price: int, extra: String, owned: bool, equipped: bool) -> String:
	if equipped:
		return "[Equipped]  %s%s   (click to take off)" % [name_, extra]
	if owned:
		return "%s%s   (owned, click to wear)" % [name_, extra]
	return "%s%s   -   %d gold" % [name_, extra, price]


func _refresh_outfits() -> void:
	outfit_info.text = "Gold: %d" % GameState.gold
	for id in Outfits.HATS:
		var h: Dictionary = Outfits.HATS[id]
		var owned: bool = id in GameState.hats
		var b: Button = outfit_buttons["hat:" + id]
		b.visible = owned or (not h.get("unique", false) and h.get("shop", "brann") == outfit_shop)
		b.text = _outfit_label(h.name, h.price, "", owned, GameState.hat == id)
		b.disabled = not owned and GameState.gold < h.price
	for id in Outfits.ARMOR:
		var a: Dictionary = Outfits.ARMOR[id]
		var owned: bool = id in GameState.armors
		var b: Button = outfit_buttons["armor:" + id]
		b.visible = owned or (not a.get("unique", false) and a.get("shop", "brann") == outfit_shop)
		b.text = _outfit_label(a.name, a.price, "  (Def +%d)" % a.def, owned, GameState.armor == id)
		b.disabled = not owned and GameState.gold < a.price
	(outfit_buttons["back"] as Button).text = "Leave the counter"
	outfit_preview.queue_redraw()


func _refresh_shop() -> void:
	var gs := GameState
	shop_info.text = "Gold: %d     Seeds: %d     Potions: %d\nCrops: %d     Fish: %d     Mushrooms: %d" % [
		gs.gold, gs.seeds, gs.potions, gs.crops, gs.fish, gs.mushrooms]
	var b: Dictionary = shop_buttons
	b.seed.text = "Buy a seed (%d gold)" % gs.SEED_PRICE
	b.seed.disabled = gs.gold < gs.SEED_PRICE
	b.potion.text = "Buy a healing potion (%d gold)  -  Q to drink" % gs.POTION_PRICE
	b.potion.disabled = gs.gold < gs.POTION_PRICE
	if gs.damage >= gs.MAX_DAMAGE:
		b.sword.text = "Sword fully sharpened"
		b.sword.disabled = true
	else:
		b.sword.text = "Sharpen sword: damage %d -> %d (%d gold)" % [gs.damage, gs.damage + 1, gs.sword_cost()]
		b.sword.disabled = gs.gold < gs.sword_cost()
	if gs.max_hp >= gs.MAX_HP_CAP:
		b.charm.text = "Heart charms: maxed out"
		b.charm.disabled = true
	else:
		b.charm.text = "Heart charm: +2 max HP (%d gold)" % gs.charm_cost()
		b.charm.disabled = gs.gold < gs.charm_cost()
	b.sell.text = "Sell crops, fish and mushrooms (%d gold)" % gs.sale_value()
	b.sell.disabled = gs.sale_value() <= 0
	b.leave.text = "Leave"


func _shop_buy_seed() -> void:
	if GameState.gold >= GameState.SEED_PRICE:
		GameState.gold -= GameState.SEED_PRICE
		GameState.seeds += 1
	_refresh_shop()


func _shop_buy_potion() -> void:
	if GameState.buy_potion():
		hud.toast("Bought a healing potion.")
	_refresh_shop()


func _shop_upgrade_sword() -> void:
	if GameState.upgrade_sword():
		hud.toast("Your sword hits harder now!")
	_refresh_shop()


func _shop_buy_charm() -> void:
	if GameState.buy_charm():
		hud.toast("Max HP is now %d." % GameState.max_hp)
	_refresh_shop()


func _shop_sell() -> void:
	hud.toast("Sold for %d gold!" % GameState.sell_all())
	_refresh_shop()


# t: 0..1 where 0.25 is 6am, 0.5 noon, 0.75 6pm.
func daylight(t: float) -> Color:
	var sun := sin((t - 0.25) * TAU)
	var brightness := clampf(sun * 0.5 + 0.6, 0.0, 1.0)
	return Color(0.25, 0.28, 0.5).lerp(Color.WHITE, brightness)
