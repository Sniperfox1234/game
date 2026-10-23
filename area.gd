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
const InfoMenuScript := preload("res://info_menu.gd")
const PetScript := preload("res://pet.gd")
const Outfits := preload("res://outfits.gd")
const TOWN := preload("res://assets/town/tiles.png")
const DUNGEON := preload("res://assets/dungeon/tiles.png")
const FARM_SCENE := "res://farm.tscn"
const TOWN_SCENE := "res://town.tscn"
const CAVE_SCENE := "res://dungeon.tscn"
const HINT := "Space: act/attack   X: attack   Shift: dash   Q: potion"
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
var pet_entry := {}

var fish_state := FishState.NONE
var fish_timer := 0.0
var fish_pond: Node2D

var raid_timer := 6.0
var was_night := false

var menu: PanelContainer
var menu_fill := Callable()
var shop_layer := CanvasLayer.new()
var shop_panel := PanelContainer.new()
var shop_info := Label.new()
var shop_buttons := {}
var outfit_panel := PanelContainer.new()
var outfit_info := Label.new()
var outfit_buttons := {} # "hat:crown" / "armor:plate" / "back" -> Button
var outfit_preview := Node2D.new()
var outfit_backdrop := ColorRect.new()


func begin(tex: Texture2D) -> void:
	ground.tile_set = Tiles.tileset(tex)
	ground.z_index = -10
	add_child(ground)
	world.y_sort_enabled = true
	add_child(world)
	GameState.day_changed.connect(_on_new_day)


func set_tile(x: int, y: int, idx: int) -> void:
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


# Call last in _ready: adds the lighting layer, HUD and shop panel on top of everything.
func finish(hint: String = HINT) -> void:
	add_child(canvas_mod)
	hud = HudScript.new()
	hud.hint = hint
	add_child(hud)
	hud.dialogue_changed.connect(func(active: bool): freeze(active))
	_build_shop_panel()
	menu = InfoMenuScript.new()
	shop_layer.add_child(menu)
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
	GameState.next_spawn = spawn
	get_tree().change_scene_to_file(scene)


# ---------- scenery helpers ----------

func add_tree(tile: Vector2i, kind: int) -> void:
	var tops := [4, 3, 4]
	var bottoms := [16, 15, 16]
	var tree := Node2D.new()
	tree.position = Vector2(tile.x * 16, (tile.y + 1) * 16)
	tree.add_child(Tiles.sprite(TOWN, tops[kind], Vector2(0, -32)))
	tree.add_child(Tiles.sprite(TOWN, bottoms[kind], Vector2(0, -16)))
	world.add_child(tree)
	add_blocker(tree, Rect2(3, -8, 10, 8))


func add_small_tree(tile: Vector2i, choppable := true) -> void:
	var tree := Node2D.new()
	tree.position = Vector2(tile.x * 16, (tile.y + 1) * 16)
	tree.add_child(Tiles.sprite(TOWN, 28, Vector2(0, -16)))
	world.add_child(tree)
	var body := add_blocker(tree, Rect2(4, -8, 8, 8))
	if not choppable:
		return
	var entry := {"node": tree, "hp": 3, "body": body}
	choppables.append(entry)
	add_interactable(tree, 22.0, func(): _chop(entry), Rect2(), func(): return tree.visible)


func _chop(entry: Dictionary) -> void:
	var tree: Node2D = entry.node
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
	elif event.is_action_pressed("potion"):
		if GameState.use_potion():
			hud.toast("Glug! +5 HP")
		elif GameState.potions <= 0:
			hud.toast("You have no potions.")
		else:
			hud.toast("You're already at full health.")


# ---------- per-frame ----------

func _process(delta: float) -> void:
	if use_daylight:
		canvas_mod.color = daylight(GameState.time_of_day)
	_fishing_tick(delta)
	if raids:
		_raid_tick(delta)
	_area_process(delta)


func _area_process(_delta: float) -> void:
	pass


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
		hud.toast("A bite! Press Space!")
	else:
		_end_fishing("It got away...")


func _fish_press() -> void:
	if fish_state == FishState.WAIT:
		_end_fishing("Too early! You scared the fish.")
		return
	var r := randf()
	if r < 0.1:
		_end_fishing("You reeled in an old boot. Nice.")
	elif r < 0.18:
		GameState.gold += 15
		_end_fishing("You found 15 gold in the mud!")
	else:
		GameState.fish += 1
		_end_fishing("Caught a fish! (%d)" % GameState.fish)


func _end_fishing(msg: String) -> void:
	fish_state = FishState.NONE
	fish_pond.call("reset")
	freeze(false)
	hud.toast(msg)


# ---------- monsters ----------

func spawn_enemy(kind: String, pos: Vector2, raider := false) -> Node:
	var e := CharacterBody2D.new()
	e.set_script(EnemyScript)
	e.setup(kind)
	e.raider = raider
	e.position = pos
	e.died.connect(_on_enemy_died)
	world.add_child(e)
	return e


func _on_enemy_died(e: Node) -> void:
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
	var quest_msg := Quests.on_kill(e.kind, e.raider)
	if quest_msg != "":
		msg += "   |   " + quest_msg
	msg += "   |   +%d XP" % e.xp_value
	if GameState.add_xp(e.xp_value) > 0:
		msg += "   LEVEL UP! You are level %d." % GameState.level
		if GameState.level == GameState.PET_LEVEL:
			msg += " Wren in town can give you a pet!"
	hud.toast(msg)


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
			hud.toast("Night falls... monsters are coming out!")
		elif not get_tree().get_nodes_in_group("raiders").is_empty():
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
	menu.setup(title)
	menu.clear()
	fill.call(menu)
	menu.visible = true
	freeze(true)
	menu.focus_button(0)


func refresh_menu() -> void:
	var idx: int = menu.focused_index()
	menu.clear()
	menu_fill.call(menu)
	menu.focus_button(idx)


func close_menu() -> void:
	menu.visible = false
	freeze(false)


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
	freeze(true)
	_refresh_shop()
	shop_panel.visible = true
	(shop_buttons["seed"] as Button).grab_focus()


func close_shop() -> void:
	shop_panel.visible = false
	freeze(false)


func _build_shop_panel() -> void:
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
		["charm", _shop_buy_charm], ["sell", _shop_sell], ["outfits", _open_outfitter], ["leave", close_shop],
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
	title.text = "Mara's Outfitter  (Esc to go back)"
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


func _open_outfitter() -> void:
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
		b.text = _outfit_label(h.name, h.price, "", owned, GameState.hat == id)
		b.disabled = not owned and GameState.gold < h.price
	for id in Outfits.ARMOR:
		var a: Dictionary = Outfits.ARMOR[id]
		var owned: bool = id in GameState.armors
		var b: Button = outfit_buttons["armor:" + id]
		b.text = _outfit_label(a.name, a.price, "  (Def +%d)" % a.def, owned, GameState.armor == id)
		b.disabled = not owned and GameState.gold < a.price
	(outfit_buttons["back"] as Button).text = "Back to the market"
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
	b.outfits.text = "Outfitter: hats and armor"
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
