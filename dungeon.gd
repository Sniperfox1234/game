extends "res://area.gd"
# The old cave: two floors of monsters, chests, and the King Slime at the bottom.

const FLOOR := [0, 0, 0, 0, 1]
const WALL := 57
const LADDER := 63
const DOOR_ROWS := Vector2i(10, 13) # tile rows of the openings in the side walls
const CHEST_CLOSED := 89
const CHEST_OPEN := 90

# Per-floor layout. Tiles are (x, y) on a 30x22 map.
const FLOORS := {
	1: {
		"light": Color(0.72, 0.72, 0.85),
		"rocks": [Vector2i(7, 6), Vector2i(12, 13), Vector2i(15, 5), Vector2i(19, 15), Vector2i(10, 17), Vector2i(23, 7), Vector2i(21, 18), Vector2i(17, 10)],
		"spawns": {
			"slime": [Vector2i(8, 4), Vector2i(11, 9), Vector2i(14, 16), Vector2i(17, 7), Vector2i(18, 18), Vector2i(21, 12)],
			"bat": [Vector2i(22, 4), Vector2i(12, 4), Vector2i(24, 16)],
			"goblin": [Vector2i(20, 9), Vector2i(25, 6), Vector2i(25, 15)],
		},
		"chest": {"tile": Vector2i(26, 19), "flag": "chest_1", "gold": 40, "potions": 2},
		"has_stairs": true,
	},
	2: {
		"light": Color(0.58, 0.58, 0.78),
		"rocks": [Vector2i(8, 7), Vector2i(11, 15), Vector2i(14, 4), Vector2i(17, 17), Vector2i(19, 9), Vector2i(22, 14), Vector2i(12, 10), Vector2i(23, 5)],
		"spawns": {
			"goblin": [Vector2i(7, 5), Vector2i(8, 17), Vector2i(12, 12)],
			"wizard": [Vector2i(15, 6), Vector2i(16, 18), Vector2i(21, 10)],
			"ghost": [Vector2i(19, 5), Vector2i(18, 14)],
			"ogre": [Vector2i(14, 9), Vector2i(21, 16)],
			"king": [Vector2i(26, 11)],
		},
		"chest": {"tile": Vector2i(27, 4), "flag": "chest_2", "gold": 150, "potions": 3},
		"has_stairs": false,
	},
}

var floor_no := 1
var data: Dictionary


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
	_build_chest()
	_spawn_enemies()

	var spawn := Vector2(36, 11 * 16 + 12)
	if GameState.next_spawn == "up":
		spawn = Vector2((map_w - 3) * 16, 11 * 16 + 12)
	GameState.next_spawn = ""
	spawn_player(spawn)
	finish("Cave floor %d   |   Space/X: sword   Shift: dash   Q: potion" % floor_no)
	if floor_no == 2:
		hud.toast("Floor 2. It's darker and meaner down here...")


func _area_process(_delta: float) -> void:
	if traveling:
		return
	var x := player.global_position.x
	if x < 8.0:
		if floor_no == 1:
			travel(TOWN_SCENE, "cave")
		else:
			GameState.cave_floor = 1
			travel(CAVE_SCENE, "up")
	elif data.has_stairs and x > map_w * 16 - 12:
		GameState.cave_floor = 2
		travel(CAVE_SCENE, "down")


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
	for i in rocks.size():
		var t: Vector2i = rocks[i]
		var rock := Node2D.new()
		rock.position = Vector2(t.x * 16, (t.y + 1) * 16)
		rock.add_child(Tiles.sprite(DUNGEON, 65 if i % 2 == 0 else 64, Vector2(0, -16)))
		world.add_child(rock)
		add_blocker(rock, Rect2(3, -10, 10, 10))


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
	GameState.potions += c.potions
	sprite.region_rect = Tiles.region(CHEST_OPEN)
	hud.toast("Treasure! +%d gold, +%d potions" % [c.gold, c.potions])


func _spawn_enemies() -> void:
	var spawns: Dictionary = data.spawns
	for kind in spawns:
		if kind == "king" and GameState.flags.get("boss_defeated", false):
			continue
		for t in spawns[kind]:
			spawn_enemy(kind, Vector2(t.x * 16 + 8, (t.y + 1) * 16))
