extends Node2D
# Shared scaffolding for the town and the cave: tile ground, y-sorted world, player, HUD, travel.

const Tiles := preload("res://tiles.gd")
const PLAYER_SCENE := preload("res://player.tscn")
const HudScript := preload("res://hud.gd")
const Quests := preload("res://quests.gd")
const TOWN := preload("res://assets/town/tiles.png")
const DUNGEON := preload("res://assets/dungeon/tiles.png")
const FARM_SCENE := "res://farm.tscn"
const TOWN_SCENE := "res://town.tscn"
const CAVE_SCENE := "res://dungeon.tscn"

var map_w := 40
var map_h := 28
var ground := TileMapLayer.new()
var world := Node2D.new()
var player: CharacterBody2D
var hud: CanvasLayer
var canvas_mod := CanvasModulate.new()
var traveling := false


func begin(tex: Texture2D) -> void:
	ground.tile_set = Tiles.tileset(tex)
	ground.z_index = -10
	add_child(ground)
	world.y_sort_enabled = true
	add_child(world)


func set_tile(x: int, y: int, idx: int) -> void:
	ground.set_cell(Vector2i(x, y), 0, Vector2i(idx % Tiles.COLS, floori(idx / float(Tiles.COLS))))


func add_blocker(parent: Node2D, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	parent.add_child(body)


func spawn_player(pos: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = pos
	world.add_child(player)
	var cam := player.get_node("Camera2D") as Camera2D
	cam.limit_right = map_w * 16
	cam.limit_bottom = map_h * 16


# Call last in _ready: adds the lighting layer and HUD on top of everything.
func finish(hint: String) -> void:
	add_child(canvas_mod)
	hud = HudScript.new()
	hud.hint = hint
	add_child(hud)
	hud.dialogue_changed.connect(_on_dialogue_changed)


func _on_dialogue_changed(active: bool) -> void:
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


func add_tree(tile: Vector2i, kind: int) -> void:
	var tops := [4, 3, 4]
	var bottoms := [16, 15, 16]
	var tree := Node2D.new()
	tree.position = Vector2(tile.x * 16, (tile.y + 1) * 16)
	tree.add_child(Tiles.sprite(TOWN, tops[kind], Vector2(0, -32)))
	tree.add_child(Tiles.sprite(TOWN, bottoms[kind], Vector2(0, -16)))
	world.add_child(tree)
	add_blocker(tree, Rect2(3, -8, 10, 8))


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
	for r in rows.size():
		for c in 4:
			base.add_child(Tiles.sprite(TOWN, rows[r][c], Vector2(c * 16, (r - 4) * 16)))
	add_blocker(base, Rect2(0, -32, 64, 32))
	return base.position + Vector2(32, 8)


# t: 0..1 where 0.25 is 6am, 0.5 noon, 0.75 6pm.
func daylight(t: float) -> Color:
	var sun := sin((t - 0.25) * TAU)
	var brightness := clampf(sun * 0.5 + 0.6, 0.0, 1.0)
	return Color(0.25, 0.28, 0.5).lerp(Color.WHITE, brightness)
