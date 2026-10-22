extends Node2D

const PLAYER_SCENE := preload("res://player.tscn")
const PlotScript := preload("res://plot.gd")
const DOOR_POS := Vector2(0, -72)
const REACH := 26.0

var player: CharacterBody2D
var plots: Array[Node2D] = []
var canvas_mod := CanvasModulate.new()
var hud := Label.new()
var toast := Label.new()
var toast_time := 0.0


func _ready() -> void:
	_build_world()
	_build_hud()
	GameState.day_changed.connect(_on_day_changed)


func _process(delta: float) -> void:
	var near := _nearest_plot()
	for plot in plots:
		plot.call("set_highlight", plot == near)

	canvas_mod.color = _daylight(GameState.time_of_day)
	_update_hud()

	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	if player.global_position.distance_to(DOOR_POS) < REACH:
		GameState.sleep()
		return
	var plot := _nearest_plot()
	if plot:
		_show_toast(plot.call("interact"))


func _build_world() -> void:
	_add_rect(Vector2(-300, -200), Vector2(600, 400), Color("5fa05a")) # grass
	_add_rect(Vector2(-40, -150), Vector2(80, 70), Color("c9a36b")) # house
	_add_rect(Vector2(-48, -170), Vector2(96, 24), Color("b8473c")) # roof
	_add_rect(Vector2(-8, -96), Vector2(16, 16), Color("5b3a1e")) # door

	_add_wall(Rect2(-320, -220, 640, 20))
	_add_wall(Rect2(-320, 200, 640, 20))
	_add_wall(Rect2(-320, -220, 20, 440))
	_add_wall(Rect2(300, -220, 20, 440))
	_add_wall(Rect2(-40, -150, 80, 70))

	for row in 3:
		for col in 5:
			var plot := Node2D.new()
			plot.set_script(PlotScript)
			plot.position = Vector2(-80 + col * 40, row * 40)
			add_child(plot)
			plots.append(plot)

	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(0, -50)
	add_child(player)

	add_child(canvas_mod)


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


func _update_hud() -> void:
	var minutes := int(GameState.time_of_day * 24.0 * 60.0)
	hud.text = "%s - Day %d  %02d:%02d\nSeeds: %d   Crops: %d\nArrows move, Space to plant/harvest, Space at the door to sleep" % [
		GameState.player_name, GameState.day,
		floori(minutes / 60.0), minutes % 60,
		GameState.seeds, GameState.crops,
	]


func _nearest_plot() -> Node2D:
	var best: Node2D = null
	var best_dist := REACH
	var feet := player.global_position + Vector2(0, 8)
	for plot in plots:
		var dist := plot.global_position.distance_to(feet)
		if dist < best_dist:
			best = plot
			best_dist = dist
	return best


func _on_day_changed(day: int) -> void:
	for plot in plots:
		plot.call("advance_day")
	_show_toast("Day %d begins!" % day)


func _show_toast(text: String) -> void:
	toast.text = text
	toast_time = 2.5


# t: 0..1 where 0.25 is 6am, 0.5 noon, 0.75 6pm.
func _daylight(t: float) -> Color:
	var sun := sin((t - 0.25) * TAU)
	var brightness := clampf(sun * 0.5 + 0.6, 0.0, 1.0)
	return Color(0.25, 0.28, 0.5).lerp(Color.WHITE, brightness)


func _add_rect(pos: Vector2, rect_size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = rect_size
	rect.color = color
	add_child(rect)


func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)
