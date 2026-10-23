extends "res://area.gd"
# Mossbrook: a small town between the farm (west) and the old cave (east).

const NpcScript := preload("res://npc.gd")
const CaveScript := preload("res://cave.gd")
const StallScript := preload("res://stall.gd")
const GRASS := [0, 0, 0, 0, 0, 0, 0, 1, 1, 2]
const PATH_TILE := 40
const PLAZA_TILE := 43
const PLAZA := Rect2i(16, 10, 9, 6)
const FARM_GAP := Rect2i(0, 12, 1, 4)
const TALK_REACH := 28.0
const RED_HOUSE := [[52, 53, 53, 54], [64, 65, 65, 66], [76, 77, 77, 79], [88, 90, 91, 88]]
const GREY_HOUSE := [[48, 49, 49, 50], [60, 61, 61, 62], [76, 77, 77, 79], [88, 90, 91, 88]]

var cave_pos := Vector2.ZERO


func _ready() -> void:
	begin(TOWN)
	_build_ground()
	build_forest(FARM_GAP)
	build_house(Vector2i(8, 4), RED_HOUSE)
	build_house(Vector2i(29, 4), GREY_HOUSE)
	_build_decor()
	_build_cave()
	_build_npcs()
	_build_market()
	add_pond(Rect2i(20, 19, 8, 4))

	var spawn := Vector2(28, 14 * 16 + 8)
	if GameState.next_spawn == "cave":
		spawn = cave_pos + Vector2(0, 12)
	GameState.next_spawn = ""
	spawn_player(spawn)
	raids = true
	finish()
	if not GameState.flags.get("seen_town", false):
		GameState.flags["seen_town"] = true
		hud.toast("Welcome to Mossbrook! Talk to people with Space.")


func _area_process(_delta: float) -> void:
	if traveling:
		return
	var p := player.global_position
	if p.x < 10.0:
		travel(FARM_SCENE, "east")
	elif absf(p.x - cave_pos.x) < 9.0 and p.y < cave_pos.y - 6.0 and p.y > cave_pos.y - 24.0:
		GameState.cave_floor = 1
		travel(CAVE_SCENE, "town")


func _build_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for y in map_h:
		for x in map_w:
			set_tile(x, y, GRASS[rng.randi() % GRASS.size()])
	# Dirt road from the farm to the plaza and on to the cave.
	for x in range(0, 17):
		set_tile(x, 13, PATH_TILE)
		set_tile(x, 14, PATH_TILE)
	for x in range(24, 36):
		set_tile(x, 13, PATH_TILE)
		set_tile(x, 14, PATH_TILE)
	for y in range(PLAZA.position.y, PLAZA.end.y):
		for x in range(PLAZA.position.x, PLAZA.end.x):
			set_tile(x, y, PLAZA_TILE)
	# Paths up to each house door.
	for y in range(8, 13):
		set_tile(10, y, PATH_TILE)
		set_tile(31, y, PATH_TILE)


func _build_decor() -> void:
	add_sign(Vector2(18 * 16 + 8, 16 * 16 + 4), [
		"Welcome to Mossbrook!",
		"Farm: west.  Old cave: east.  Pond: south.  Please do not feed the slimes.",
	])
	for t in [Vector2i(4, 7), Vector2i(5, 20), Vector2i(14, 21), Vector2i(35, 20), Vector2i(23, 6), Vector2i(13, 5)]:
		add_small_tree(t)
	for t in [Vector2i(3, 12), Vector2i(26, 17), Vector2i(34, 9)]:
		var bush := Node2D.new()
		bush.position = Vector2(t.x * 16, (t.y + 1) * 16)
		bush.add_child(Tiles.sprite(TOWN, 5, Vector2(0, -16)))
		world.add_child(bush)
		add_blocker(bush, Rect2(2, -10, 12, 10))
	for t in [Vector2i(6, 17), Vector2i(32, 18), Vector2i(15, 8), Vector2i(36, 6)]:
		add_mushroom(t)


func _build_cave() -> void:
	var cave := Node2D.new()
	cave.set_script(CaveScript)
	cave.position = Vector2(35 * 16 + 8, 13 * 16)
	world.add_child(cave)
	add_blocker(cave, Rect2(-24, -30, 14, 30))
	add_blocker(cave, Rect2(10, -30, 14, 30))
	add_blocker(cave, Rect2(-10, -30, 20, 10))
	cave_pos = cave.position
	add_sign(Vector2(33 * 16 + 8, 13 * 16), [
		"DANGER: Old cave ahead.",
		"Slimes, goblins and worse. Bring potions. Dash with Shift!",
	])


func _build_npcs() -> void:
	_add_npc("rosa", "Mayor Rosa", 99, Vector2(21 * 16 + 8, 12 * 16))
	_add_npc("gus", "Gus", 96, Vector2(31 * 16, 15 * 16))
	_add_npc("pip", "Pip", 85, Vector2(13 * 16, 17 * 16))


# Mara's market stall in the plaza; Mara herself stands behind the counter.
func _build_market() -> void:
	var stall := Node2D.new()
	stall.set_script(StallScript)
	stall.position = Vector2(18 * 16, 12 * 16)
	world.add_child(stall)
	add_blocker(stall, Rect2(-14, -12, 28, 12))
	var mara := Node2D.new()
	mara.set_script(NpcScript)
	mara.npc_id = "mara"
	mara.display_name = "Mara"
	mara.tile = 100
	mara.position = stall.position + Vector2(0, -5)
	world.add_child(mara)
	add_interactable(stall, 34.0, _open_market)


func _open_market() -> void:
	hud.say("Mara", ["Fresh seeds, potions and sharp swords! I also buy crops, fish and mushrooms."], open_shop)


func _add_npc(id: String, display: String, tile: int, pos: Vector2) -> void:
	var npc := Node2D.new()
	npc.set_script(NpcScript)
	npc.npc_id = id
	npc.display_name = display
	npc.tile = tile
	npc.position = pos
	world.add_child(npc)
	add_blocker(npc, Rect2(-4, -6, 8, 6))
	add_interactable(npc, TALK_REACH, func(): _talk(npc))


func _talk(npc: Node2D) -> void:
	var t := Quests.talk(npc.npc_id)
	var after: Callable = t.get("after", Callable())
	hud.say(npc.display_name, t.lines, func():
		if after.is_valid():
			var msg: String = after.call()
			if msg != "":
				hud.toast(msg))
