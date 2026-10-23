extends "res://area.gd"
# The old cave: slimes, a King Slime, and the way back to town.

const SlimeScript := preload("res://slime.gd")
const FLOOR := [0, 0, 0, 0, 1]
const WALL := 57
const DOOR_ROWS := Vector2i(10, 13) # tile rows of the exit gap in the left wall
const OBSTACLES := [
	Vector2i(7, 6), Vector2i(12, 13), Vector2i(15, 5), Vector2i(19, 15),
	Vector2i(10, 17), Vector2i(23, 7), Vector2i(21, 18), Vector2i(17, 10),
]
const SLIME_SPOTS := [
	Vector2i(8, 4), Vector2i(11, 9), Vector2i(14, 16), Vector2i(17, 7),
	Vector2i(18, 18), Vector2i(21, 12), Vector2i(22, 4), Vector2i(12, 4),
]
const BOSS_SPOT := Vector2i(26, 11)


func _ready() -> void:
	map_w = 30
	map_h = 22
	begin(DUNGEON)
	_build_ground()
	_build_walls()
	_build_obstacles()
	_spawn_enemies()
	spawn_player(Vector2(36, 11 * 16 + 12))
	player.can_attack = true
	player.died.connect(_on_player_died)
	GameState.next_spawn = ""
	canvas_mod.color = Color(0.72, 0.72, 0.85)
	finish("Space: swing sword")


func _process(_delta: float) -> void:
	if not traveling and player.global_position.x < 8.0:
		travel(TOWN_SCENE, "cave")


func _build_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
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
	# Open the exit and mark it with a door.
	for y in range(DOOR_ROWS.x, DOOR_ROWS.y):
		set_tile(0, y, FLOOR[0])


func _build_walls() -> void:
	var body := StaticBody2D.new()
	world.add_child(body)
	var w := map_w * 16
	var h := map_h * 16
	var door_top := DOOR_ROWS.x * 16
	var door_bottom := DOOR_ROWS.y * 16
	for r in [
		Rect2(0, 0, w, 32), Rect2(0, h - 16, w, 16), Rect2(w - 16, 0, 16, h),
		Rect2(0, 0, 16, door_top), Rect2(0, door_bottom, 16, h - door_bottom),
	]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = r.size
		shape.shape = box
		shape.position = r.get_center()
		body.add_child(shape)


func _build_obstacles() -> void:
	for i in OBSTACLES.size():
		var t: Vector2i = OBSTACLES[i]
		var rock := Node2D.new()
		rock.position = Vector2(t.x * 16, (t.y + 1) * 16)
		rock.add_child(Tiles.sprite(DUNGEON, 65 if i % 2 == 0 else 64, Vector2(0, -16)))
		world.add_child(rock)
		add_blocker(rock, Rect2(3, -10, 10, 10))


func _spawn_enemies() -> void:
	for t in SLIME_SPOTS:
		_add_slime(t, false)
	if not GameState.flags.get("boss_defeated", false):
		_add_slime(BOSS_SPOT, true)


func _add_slime(t: Vector2i, boss: bool) -> void:
	var slime := CharacterBody2D.new()
	slime.set_script(SlimeScript)
	slime.setup(boss)
	slime.position = Vector2(t.x * 16 + 8, (t.y + 1) * 16)
	slime.died.connect(_on_enemy_died)
	world.add_child(slime)


func _on_enemy_died(enemy: Node) -> void:
	var boss: bool = enemy.boss
	var gold := 50 if boss else randi_range(2, 4)
	GameState.gold += gold
	var msg := "+%d gold" % gold
	if not boss and GameState.hp < GameState.max_hp and randf() < 0.3:
		GameState.heal(1)
		msg += ", +1 HP"
	if boss:
		msg = "The King Slime is defeated! " + msg
	var quest_msg := Quests.on_kill("boss" if boss else "slime")
	if quest_msg != "":
		msg += "   |   " + quest_msg
	hud.toast(msg)


func _on_player_died() -> void:
	GameState.hp = GameState.max_hp
	var lost := int(GameState.gold * 0.1)
	GameState.gold -= lost
	GameState.flags["passed_out"] = lost
	travel(FARM_SCENE, "door")
