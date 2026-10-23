extends Node2D

const Tiles := preload("res://tiles.gd")
const PLAYER_SCENE := preload("res://player.tscn")
const PlotScript := preload("res://plot.gd")
const TOWN := preload("res://assets/town/tiles.png")

const MAP_W := 40
const MAP_H := 28
const REACH := 26.0

# Kenney Tiny Town tile indices.
const GRASS := [0, 0, 0, 0, 0, 0, 0, 1, 1, 2]
const FIELD := {
	"tl": 12, "t": 13, "tr": 14,
	"l": 24, "c": 25, "r": 26,
	"bl": 36, "b": 37, "br": 38,
}
const FIELD_RECT := Rect2i(13, 12, 14, 8)
const HOUSE_TILE := Vector2i(17, 3)
const EAST_GAP := Rect2i(MAP_W - 1, 12, 1, 4) # the road to town

var player: CharacterBody2D
var plots: Array[Node2D] = []
var ground := TileMapLayer.new()
var world := Node2D.new()
var door_pos := Vector2.ZERO
var canvas_mod := CanvasModulate.new()
var hud := Label.new()
var toast := Label.new()
var toast_time := 0.0
var shop_pos := Vector2.ZERO
var leaving := false
var shop_panel := PanelContainer.new()
var shop_info := Label.new()


func _ready() -> void:
	_build_ground()
	world.y_sort_enabled = true
	add_child(world)
	_build_house()
	_build_trees()
	_build_plots()
	_build_shop()
	_build_player()
	add_child(canvas_mod)
	_build_hud()
	_restore_plots()
	GameState.day_changed.connect(_on_day_changed)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0].begins_with("shot="):
		_screenshot_and_quit(args[0].trim_prefix("shot="))


func _process(delta: float) -> void:
	var near := _nearest_plot()
	for plot in plots:
		plot.call("set_highlight", plot == near)

	canvas_mod.color = _daylight(GameState.time_of_day)
	_update_hud()
	if not leaving and player.global_position.x > (MAP_W - 1) * 16 - 4:
		leaving = true
		_stash()
		GameState.next_spawn = "west"
		get_tree().change_scene_to_file("res://town.tscn")

	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if shop_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_shop()
		return
	if not event.is_action_pressed("ui_accept"):
		return
	if player.global_position.distance_to(door_pos) < REACH:
		GameState.sleep()
		_save()
		_show_toast("Good morning! Game saved.")
		return
	if player.global_position.distance_to(shop_pos) < REACH + 6.0:
		_open_shop()
		return
	var plot := _nearest_plot()
	if plot:
		_show_toast(plot.call("interact"))


func _build_ground() -> void:
	ground.tile_set = Tiles.tileset(TOWN)
	ground.z_index = -10
	add_child(ground)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in MAP_H:
		for x in MAP_W:
			_set_tile(x, y, GRASS[rng.randi() % GRASS.size()])

	var f := FIELD_RECT
	for y in range(f.position.y, f.end.y):
		for x in range(f.position.x, f.end.x):
			var top := y == f.position.y
			var bottom := y == f.end.y - 1
			var left := x == f.position.x
			var right := x == f.end.x - 1
			var key := "c"
			if top:
				key = "tl" if left else ("tr" if right else "t")
			elif bottom:
				key = "bl" if left else ("br" if right else "b")
			elif left:
				key = "l"
			elif right:
				key = "r"
			_set_tile(x, y, FIELD[key])


func _set_tile(x: int, y: int, idx: int) -> void:
	ground.set_cell(Vector2i(x, y), 0, Vector2i(idx % Tiles.COLS, floori(idx / float(Tiles.COLS))))


# A 4x4 house: roof, roof, wall, wall. Origin of the node is its bottom-left corner.
func _build_house() -> void:
	var base := Node2D.new()
	base.position = Vector2(HOUSE_TILE.x * 16, (HOUSE_TILE.y + 4) * 16)
	world.add_child(base)

	var rows := [
		[52, 53, 53, 54],
		[64, 65, 65, 66],
		[76, 77, 77, 79],
		[88, 90, 91, 88],
	]
	for r in rows.size():
		for c in 4:
			base.add_child(Tiles.sprite(TOWN, rows[r][c], Vector2(c * 16, (r - 4) * 16)))
	_add_blocker(base, Rect2(0, -32, 64, 32))
	door_pos = base.position + Vector2(32, 8)


func _build_trees() -> void:
	# Forest wall across the top, then down the sides and along the bottom.
	for x in MAP_W:
		_add_tree(Vector2i(x, 1), x % 3)
	for y in range(3, MAP_H, 2):
		_add_tree(Vector2i(0, y), y % 3)
		if not EAST_GAP.has_point(Vector2i(MAP_W - 1, y)):
			_add_tree(Vector2i(MAP_W - 1, y), (y + 1) % 3)
	for x in range(2, MAP_W - 2, 2):
		_add_tree(Vector2i(x, MAP_H - 1), (x + 2) % 3)

	# A few small trees and mushrooms for variety.
	for t in [Vector2i(8, 8), Vector2i(31, 9), Vector2i(9, 22), Vector2i(30, 21)]:
		var tree := Node2D.new()
		tree.position = Vector2(t.x * 16, (t.y + 1) * 16)
		tree.add_child(Tiles.sprite(TOWN, 28, Vector2(0, -16)))
		world.add_child(tree)
		_add_blocker(tree, Rect2(4, -8, 8, 8))
	for t in [Vector2i(11, 14), Vector2i(29, 16), Vector2i(20, 24)]:
		var mush := Node2D.new()
		mush.position = Vector2(t.x * 16, (t.y + 1) * 16)
		mush.add_child(Tiles.sprite(TOWN, 29, Vector2(0, -16)))
		world.add_child(mush)


func _add_tree(tile: Vector2i, kind: int) -> void:
	var tops := [4, 3, 4]
	var bottoms := [16, 15, 16]
	var tree := Node2D.new()
	tree.position = Vector2(tile.x * 16, (tile.y + 1) * 16)
	tree.add_child(Tiles.sprite(TOWN, tops[kind], Vector2(0, -32)))
	tree.add_child(Tiles.sprite(TOWN, bottoms[kind], Vector2(0, -16)))
	world.add_child(tree)
	_add_blocker(tree, Rect2(3, -8, 10, 8))


func _build_plots() -> void:
	for row in 3:
		for col in 5:
			var tile := Vector2(15 + col * 2, 14 + row * 2)
			var plot := Node2D.new()
			plot.set_script(PlotScript)
			plot.position = (tile + Vector2(0.5, 0.5)) * 16
			plot.z_index = -5
			world.add_child(plot)
			plots.append(plot)


# A little market stall east of the house. Origin is its bottom-centre.
func _build_shop() -> void:
	var stall := Node2D.new()
	stall.position = Vector2(24 * 16, 7 * 16)
	stall.set_script(preload("res://stall.gd"))
	world.add_child(stall)
	_add_blocker(stall, Rect2(-14, -12, 28, 12))
	shop_pos = stall.position + Vector2(0, 8)


func _open_shop() -> void:
	player.set_physics_process(false)
	_refresh_shop()
	shop_panel.visible = true
	(shop_panel.find_children("*", "Button", true, false)[0] as Button).grab_focus()


func _close_shop() -> void:
	shop_panel.visible = false
	player.set_physics_process(true)


func _refresh_shop() -> void:
	shop_info.text = "Gold: %d    Seeds: %d    Crops: %d" % [GameState.gold, GameState.seeds, GameState.crops]


func _on_buy() -> void:
	if not GameState.buy_seed():
		_show_toast("Not enough gold!")
	_refresh_shop()


func _on_sell() -> void:
	if GameState.crops <= 0:
		_show_toast("You have no crops to sell.")
	else:
		_show_toast("Sold crops for %d gold!" % GameState.sell_crops())
	_refresh_shop()


func _stash() -> void:
	GameState.plot_data = plots.map(func(p): return p.call("get_data"))
	GameState.plots_day = GameState.day


func _save() -> void:
	_stash()
	GameState.save_game()


# Crops keep growing while the player is away, so catch up on the days that passed.
func _restore_plots() -> void:
	if GameState.plot_data.size() == plots.size():
		for i in plots.size():
			plots[i].call("set_data", GameState.plot_data[i])
		for d in maxi(GameState.day - GameState.plots_day, 0):
			for plot in plots:
				plot.call("advance_day")
	GameState.plots_day = GameState.day
	var lost: int = GameState.flags.get("passed_out", -1)
	if lost >= 0:
		GameState.flags.erase("passed_out")
		_show_toast("You passed out in the cave and woke up at home. Lost %d gold." % lost)


func _build_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = door_pos + Vector2(0, 14)
	if GameState.next_spawn == "east":
		player.position = Vector2((MAP_W - 2) * 16, 14 * 16 + 8)
	GameState.next_spawn = ""
	world.add_child(player)


func _add_blocker(parent: Node2D, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	parent.add_child(body)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_outline_color", Color.BLACK)
	hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud)

	toast.position = Vector2(16, 590)
	toast.add_theme_font_size_override("font_size", 22)
	toast.add_theme_color_override("font_outline_color", Color.BLACK)
	toast.add_theme_constant_override("outline_size", 6)
	layer.add_child(toast)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "Market stall  (Esc to leave)"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	shop_info.add_theme_font_size_override("font_size", 18)
	box.add_child(shop_info)
	var buy := Button.new()
	buy.text = "Buy a seed (%d gold)" % GameState.SEED_PRICE
	buy.pressed.connect(_on_buy)
	box.add_child(buy)
	var sell := Button.new()
	sell.text = "Sell all crops (%d gold each)" % GameState.CROP_PRICE
	sell.pressed.connect(_on_sell)
	box.add_child(sell)
	var leave := Button.new()
	leave.text = "Leave"
	leave.pressed.connect(_close_shop)
	box.add_child(leave)
	shop_panel.add_child(box)
	shop_panel.position = Vector2(380, 180)
	shop_panel.custom_minimum_size = Vector2(380, 0)
	shop_panel.visible = false
	layer.add_child(shop_panel)


func _update_hud() -> void:
	var minutes := int(GameState.time_of_day * 24.0 * 60.0)
	hud.text = "%s - Day %d  %02d:%02d\nGold: %d   HP: %d/%d   Seeds: %d   Crops: %d\nSpace: plant/harvest, trade at the stall, sleep+save at the door. Walk east to town." % [
		GameState.player_name, GameState.day,
		floori(minutes / 60.0), minutes % 60,
		GameState.gold, GameState.hp, GameState.max_hp, GameState.seeds, GameState.crops,
	]


func _nearest_plot() -> Node2D:
	var best: Node2D = null
	var best_dist := REACH
	var feet := player.global_position + Vector2(0, -2)
	for plot in plots:
		var dist := plot.global_position.distance_to(feet)
		if dist < best_dist:
			best = plot
			best_dist = dist
	return best


func _on_day_changed(day: int) -> void:
	for plot in plots:
		plot.call("advance_day")
	GameState.plots_day = day
	_show_toast("Day %d begins!" % day)


func _show_toast(text: String) -> void:
	toast.text = text
	toast_time = 2.5


# t: 0..1 where 0.25 is 6am, 0.5 noon, 0.75 6pm.
func _daylight(t: float) -> Color:
	var sun := sin((t - 0.25) * TAU)
	var brightness := clampf(sun * 0.5 + 0.6, 0.0, 1.0)
	return Color(0.25, 0.28, 0.5).lerp(Color.WHITE, brightness)


# Dev hook: Godot --path . -- shot=/path/out.png saves a noon screenshot and quits.
func _screenshot_and_quit(path: String) -> void:
	GameState.time_of_day = 0.5
	(player.get_node("Camera2D") as Camera2D).zoom = Vector2(1.6, 1.6)
	for i in 8:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
