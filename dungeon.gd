extends "res://area.gd"
# The old cave. Floors 1 and 2 are full of ordinary monsters, with chests and ore to find.
# Floor 3 is the boss chamber: just the King Slime, an arena, and a legendary prize.

const PixelArt := preload("res://pixel_art.gd")
const DecorScript := preload("res://decor.gd")
const FLOOR := [0, 0, 0, 0, 1]
const WALL := 57
const LADDER := 63
const DOOR_ROWS := Vector2i(10, 13) # tile rows of the openings in the side walls
const CHEST_CLOSED := 89
const CHEST_OPEN := 90
const BOSS_SPOT := Vector2i(21, 11)

# Per-floor layout. Tiles are (x, y) on a 30x22 map.
const FLOORS := {
	1: {
		"name": "Cave, floor 1",
		"light": Color(0.72, 0.72, 0.85),
		"rocks": [Vector2i(7, 6), Vector2i(12, 13), Vector2i(15, 5), Vector2i(19, 15), Vector2i(10, 17), Vector2i(23, 7), Vector2i(21, 18), Vector2i(17, 10)],
		"ore": [Vector2i(5, 8), Vector2i(9, 19), Vector2i(13, 3), Vector2i(24, 9), Vector2i(27, 13), Vector2i(6, 15)],
		"spawns": {
			"slime": [Vector2i(8, 4), Vector2i(11, 9), Vector2i(14, 16), Vector2i(17, 7), Vector2i(18, 18), Vector2i(21, 12)],
			"bat": [Vector2i(22, 4), Vector2i(12, 4), Vector2i(24, 16)],
			"goblin": [Vector2i(20, 9), Vector2i(25, 6), Vector2i(25, 15)],
		},
		"chest": {"tile": Vector2i(26, 19), "flag": "chest_1", "gold": 40, "potions": 2},
		"has_stairs": true,
	},
	2: {
		"name": "Cave, floor 2",
		"light": Color(0.58, 0.58, 0.78),
		"rocks": [Vector2i(8, 7), Vector2i(11, 15), Vector2i(14, 4), Vector2i(17, 17), Vector2i(19, 9), Vector2i(22, 14), Vector2i(12, 10), Vector2i(23, 5)],
		"ore": [Vector2i(5, 10), Vector2i(10, 5), Vector2i(16, 13), Vector2i(20, 19), Vector2i(25, 17), Vector2i(25, 7), Vector2i(9, 18)],
		"spawns": {
			"goblin": [Vector2i(7, 5), Vector2i(8, 17), Vector2i(12, 12), Vector2i(21, 4)],
			"wizard": [Vector2i(15, 6), Vector2i(16, 18), Vector2i(21, 10)],
			"ghost": [Vector2i(19, 5), Vector2i(18, 14)],
			"ogre": [Vector2i(14, 9), Vector2i(21, 16)],
		},
		"chest": {"tile": Vector2i(27, 4), "flag": "chest_2", "gold": 150, "potions": 3},
		"has_stairs": true,
		"boss_gate": true,
	},
	3: {
		"name": "The King's Chamber",
		"light": Color(0.5, 0.44, 0.72),
		"rocks": [Vector2i(5, 5), Vector2i(5, 16), Vector2i(26, 4), Vector2i(26, 17), Vector2i(11, 3), Vector2i(11, 18), Vector2i(17, 3), Vector2i(17, 18)],
		"ore": [],
		"spawns": {"king": [BOSS_SPOT]},
		"has_stairs": false,
		"arena": true,
	},
}

var floor_no := 1
var data: Dictionary
var royal_chest: Node2D
var royal_light: PointLight2D


func _ready() -> void:
	map_w = 30
	map_h = 22
	floor_no = GameState.cave_floor
	data = FLOORS[floor_no]
	begin(DUNGEON)
	use_daylight = false
	canvas_mod.color = data.light
	_build_ground()
	_build_walls()
	_build_rocks()
	var ore: Array = data.ore
	for i in ore.size():
		add_ore(ore[i], 12 if i % 2 == 0 else 13)
	if data.has("chest"):
		_build_chest()
	if data.get("boss_gate", false):
		_build_boss_gate()
	if data.get("arena", false):
		_build_arena()
	_spawn_enemies()

	var spawn := Vector2(36, 11 * 16 + 12)
	if GameState.next_spawn == "up":
		spawn = Vector2((map_w - 3) * 16, 11 * 16 + 12)
	GameState.next_spawn = ""
	spawn_player(spawn)
	finish("%s  |  Space/X: sword  Shift: dash  Q: potion  E: eat" % data.name)
	_announce()


func _announce() -> void:
	if floor_no == 2:
		hud.toast("Floor 2. It's darker and meaner down here...")
	elif floor_no == 3:
		if GameState.flags.get("boss_defeated", false):
			hud.toast("The chamber is quiet. The King Slime is no more.")
		else:
			hud.toast("WARNING: The King Slime awaits! Heal up, then fight!")


func _area_process(_delta: float) -> void:
	if traveling:
		return
	var x := player.global_position.x
	if x < 8.0:
		if floor_no == 1:
			travel(TOWN_SCENE, "cave")
		else:
			GameState.cave_floor = floor_no - 1
			travel(CAVE_SCENE, "up")
	elif data.has_stairs and x > map_w * 16 - 12:
		GameState.cave_floor = floor_no + 1
		travel(CAVE_SCENE, "down")


# ---------- map ----------

func _build_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5 + floor_no
	for y in map_h:
		for x in map_w:
			set_tile(x, y, FLOOR[rng.randi() % FLOOR.size()])
	for x in map_w:
		set_tile(x, 0, WALL)
		set_tile(x, 1, WALL)
		set_tile(x, map_h - 1, WALL)
	for y in map_h:
		set_tile(0, y, WALL)
		set_tile(map_w - 1, y, WALL)
	for y in range(DOOR_ROWS.x, DOOR_ROWS.y):
		set_tile(0, y, FLOOR[0])
		if data.has_stairs:
			set_tile(map_w - 1, y, FLOOR[0])
	if data.has_stairs:
		set_tile(map_w - 2, 11, LADDER)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	world.add_child(body)
	var w := map_w * 16
	var h := map_h * 16
	var top := DOOR_ROWS.x * 16
	var bottom := DOOR_ROWS.y * 16
	var rects := [
		Rect2(0, 0, w, 32), Rect2(0, h - 16, w, 16),
		Rect2(0, 0, 16, top), Rect2(0, bottom, 16, h - bottom),
	]
	if data.has_stairs:
		rects.append(Rect2(w - 16, 0, 16, top))
		rects.append(Rect2(w - 16, bottom, 16, h - bottom))
	else:
		rects.append(Rect2(w - 16, 0, 16, h))
	for r in rects:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = r.size
		shape.shape = box
		shape.position = r.get_center()
		body.add_child(shape)


func _build_rocks() -> void:
	var rocks: Array = data.rocks
	var arena: bool = data.get("arena", false)
	for i in rocks.size():
		var t: Vector2i = rocks[i]
		var rock := Node2D.new()
		rock.position = Vector2(t.x * 16, (t.y + 1) * 16)
		if arena:
			# Stone pillars topped with a gargoyle.
			rock.add_child(Tiles.sprite(DUNGEON, 31, Vector2(0, -16)))
			rock.add_child(Tiles.sprite(DUNGEON, 19, Vector2(0, -32)))
		else:
			rock.add_child(Tiles.sprite(DUNGEON, 65 if i % 2 == 0 else 64, Vector2(0, -16)))
		world.add_child(rock)
		add_blocker(rock, Rect2(3, -10, 10, 10))


func _sprite_at(texture: Texture2D, pos: Vector2, z := 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.position = pos
	s.z_index = z
	world.add_child(s)
	return s


# The doorway at the east end of floor 2: gargoyles, a warning sign and a glowing red label.
func _build_boss_gate() -> void:
	for y in [9, 13]:
		var g := Node2D.new()
		g.position = Vector2((map_w - 2) * 16, (y + 1) * 16)
		g.add_child(Tiles.sprite(DUNGEON, 19, Vector2(0, -16)))
		world.add_child(g)
	var label := Label.new()
	label.text = "BOSS CHAMBER"
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("ff6b7b"))
	label.add_theme_color_override("font_outline_color", Color("2e2233"))
	label.add_theme_constant_override("outline_size", 3)
	label.position = Vector2((map_w - 5) * 16 - 4, 8 * 16 + 4)
	label.z_index = 30
	world.add_child(label)
	add_sign(Vector2((map_w - 5) * 16 + 8, 14 * 16), [
		"WARNING: Beyond this gate lies the King Slime's chamber.",
		"No ordinary monsters there, just him. Heal up, bring potions and food, and don't stand still!",
	])


# The boss chamber: a glowing rune ring, torches along the wall, and gargoyle pillars.
func _build_arena() -> void:
	var centre := Vector2(BOSS_SPOT.x * 16 + 8, BOSS_SPOT.y * 16 + 8)
	var rune := PixelArt.rune_circle(150, 100)
	_sprite_at(rune, centre - Vector2(rune.get_width(), rune.get_height()) / 2.0, -8)
	for x in [3, 7, 11, 15, 19, 23, 27]:
		var t := Node2D.new()
		t.set_script(DecorScript)
		t.kind = "torch"
		t.position = Vector2(x * 16 + 4, 12)
		world.add_child(t)
	# If the King is already beaten, his chest is still here (open once you've claimed it).
	if GameState.flags.get("boss_defeated", false):
		_spawn_royal_chest(centre + Vector2(0, 14), false)


# ---------- chests ----------

func _build_chest() -> void:
	var c: Dictionary = data.chest
	var t: Vector2i = c.tile
	var chest := Node2D.new()
	chest.position = Vector2(t.x * 16 + 8, (t.y + 1) * 16)
	var looted: bool = GameState.flags.get(c.flag, false)
	var sprite := Tiles.sprite(DUNGEON, CHEST_OPEN if looted else CHEST_CLOSED, Vector2(-8, -16))
	chest.add_child(sprite)
	world.add_child(chest)
	add_blocker(chest, Rect2(-6, -8, 12, 8))
	add_interactable(chest, 24.0, func(): _open_chest(c, sprite))


func _open_chest(c: Dictionary, sprite: Sprite2D) -> void:
	if GameState.flags.get(c.flag, false):
		hud.toast("The chest is empty.")
		return
	GameState.flags[c.flag] = true
	GameState.gold += c.gold
	GameState.potions = mini(GameState.potions + c.potions, GameState.POTION_CAP)
	sprite.region_rect = Tiles.region(CHEST_OPEN)
	hud.toast("Treasure! +%d gold, +%d potions" % [c.gold, c.potions])


# ---------- boss prize ----------

func _after_enemy_died(e: Node) -> void:
	if e.boss and floor_no == 3:
		hud.toast("THE KING SLIME IS DEFEATED!  A royal chest appears...")
		_spawn_royal_chest(e.position + Vector2(0, 8), true)


func _spawn_royal_chest(feet: Vector2, with_burst: bool) -> void:
	var opened: bool = GameState.flags.get("royal_chest", false)
	royal_chest = Node2D.new()
	royal_chest.position = feet
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.royal_chest(opened)
	sprite.centered = false
	sprite.position = Vector2(-14, -25)
	sprite.name = "Sprite"
	royal_chest.add_child(sprite)
	royal_light = PointLight2D.new()
	royal_light.texture = PixelArt.light()
	royal_light.color = Color(1.0, 0.85, 0.4)
	royal_light.texture_scale = 1.4
	royal_light.energy = 0.9
	royal_light.position = Vector2(0, -12)
	royal_chest.add_child(royal_light)
	world.add_child(royal_chest)
	add_blocker(royal_chest, Rect2(-12, -10, 24, 10))
	if not opened:
		royal_chest.add_child(_sparkles())
	add_interactable(royal_chest, 28.0, _open_royal_chest)
	if with_burst:
		sprite.modulate = Color(3, 3, 3)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.8)


func _sparkles() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Sparkles"
	p.position = Vector2(0, -14)
	p.amount = 22
	p.lifetime = 1.6
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 22.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.8
	p.color = Color("ffe08a")
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 9.0
	p.z_index = 20
	return p


func _open_royal_chest() -> void:
	if GameState.flags.get("royal_chest", false):
		hud.toast("The royal chest is empty. You already have the King's treasure!")
		return
	hud.say("Royal Chest", [
		"The lid creaks open and golden light pours out...",
		"You found the SLIMEBLADE! A legendary sword that glows green. +3 damage and a longer reach!",
		"You found the SLIME KING'S CROWN! It sparkles with every step.",
		"Plus 400 gold, 3 potions and a rush of experience!",
	], _claim_prize)


func _claim_prize() -> void:
	GameState.flags["royal_chest"] = true
	GameState.flags["slimeblade"] = true
	GameState.damage += 3
	GameState.gold += 400
	GameState.potions = mini(GameState.potions + 3, GameState.POTION_CAP)
	if not "slime_crown" in GameState.hats:
		GameState.hats.append("slime_crown")
	GameState.hat = "slime_crown"
	GameState.equipment_changed.emit()
	var levels := GameState.add_xp(150)
	(royal_chest.get_node("Sprite") as Sprite2D).texture = PixelArt.royal_chest(true)
	var sparkles := royal_chest.get_node_or_null("Sparkles")
	if sparkles:
		sparkles.queue_free()
	hud.toast("Slimeblade and Slime King's Crown acquired!" + ("  LEVEL UP! You are level %d." % GameState.level if levels > 0 else ""))
	GameState.save_game()


# ---------- monsters ----------

func _spawn_enemies() -> void:
	var spawns: Dictionary = data.spawns
	for kind in spawns:
		if kind == "king" and GameState.flags.get("boss_defeated", false):
			continue
		for t in spawns[kind]:
			spawn_enemy(kind, Vector2(t.x * 16 + 8, (t.y + 1) * 16))
