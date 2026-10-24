extends Node2D
# An animated pond you can fish in. Origin is the top-left corner; `size` is in pixels.

var size := Vector2(96, 64)
var plain := false # open sea: the terrain already draws the water, so skip the pond surface and bank
var bobber := Vector2.INF
var bite := false
var _t := randf() * 10.0
var _splash_time := 0.0
var _splash_color := Color.WHITE
var _splash_at := Vector2.ZERO


func _ready() -> void:
	z_index = -5
	if plain:
		return
	var surface := ColorRect.new()
	surface.size = size
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader")
	mat.set_shader_parameter("pond_px", size)
	surface.material = mat
	surface.show_behind_parent = true # so the bank, lily pads and bobber draw on top of it
	add_child(surface)


func _process(delta: float) -> void:
	_t += delta
	_splash_time = maxf(_splash_time - delta, 0.0)
	queue_redraw()


func world_rect() -> Rect2:
	return Rect2(global_position, size)


func cast(from_world: Vector2) -> void:
	var local := from_world - global_position
	bobber = Vector2(clampf(local.x, 8.0, size.x - 8.0), clampf(local.y, 8.0, size.y - 8.0))
	bite = false


func reset() -> void:
	bobber = Vector2.INF
	bite = false


# A ring of droplets in the catch's rarity colour where the bobber was.
func splash(color: Color) -> void:
	_splash_time = 0.9
	_splash_color = color
	_splash_at = bobber if bobber != Vector2.INF else size / 2.0


func _draw() -> void:
	if plain:
		_draw_bobber()
		return
	# A sandy, softly shaded bank around the water.
	var sand := Color("d8c48a")
	var wet := Color("8a7448")
	draw_rect(Rect2(-5, -5, size.x + 10, 5), wet)
	draw_rect(Rect2(-5, size.y, size.x + 10, 5), wet)
	draw_rect(Rect2(-5, 0, 5, size.y), wet)
	draw_rect(Rect2(size.x, 0, 5, size.y), wet)
	draw_rect(Rect2(-3, -3, size.x + 6, 3), sand)
	draw_rect(Rect2(-3, size.y, size.x + 6, 3), sand)
	draw_rect(Rect2(-3, 0, 3, size.y), sand)
	draw_rect(Rect2(size.x, 0, 3, size.y), sand)
	for p in [Vector2(0.2, 0.3), Vector2(0.7, 0.6), Vector2(0.45, 0.8)]:
		var c: Vector2 = size * p + Vector2(sin(_t * 0.8 + p.x * 9.0) * 1.2, cos(_t * 0.7 + p.y * 7.0) * 0.8)
		draw_circle(c, 3.6, Color("2f7a3a"))
		draw_circle(c + Vector2(-0.6, -0.6), 2.9, Color("52b050"))
		draw_circle(c + Vector2(-1.0, -1.0), 1.1, Color("8fdc7a"))
	_draw_bobber()


func _draw_bobber() -> void:
	if bobber != Vector2.INF:
		var shake := sin(_t * 40.0) * 1.5 if bite else sin(_t * 3.0) * 0.5
		var pos := bobber + Vector2(0, shake)
		draw_circle(pos, 2.5, Color.WHITE)
		draw_rect(Rect2(pos + Vector2(-2.5, -0.5), Vector2(5, 3)), Color("e84a5f"))
		if bite:
			var font := ThemeDB.fallback_font
			draw_string_outline(font, pos + Vector2(-3, -6), "!", HORIZONTAL_ALIGNMENT_CENTER, 6, 14, 4, Color.BLACK)
			draw_string(font, pos + Vector2(-3, -6), "!", HORIZONTAL_ALIGNMENT_CENTER, 6, 14, Color("f2c14e"))
	if _splash_time > 0.0:
		var u := 1.0 - _splash_time / 0.9
		for k in 14:
			var a := TAU * k / 14.0
			var r := 3.0 + u * 14.0
			var p := _splash_at + Vector2(cos(a) * r, sin(a) * r * 0.6 - sin(u * PI) * 8.0)
			draw_rect(Rect2(p.x - 1, p.y - 1, 2, 2), Color(_splash_color, 1.0 - u))
