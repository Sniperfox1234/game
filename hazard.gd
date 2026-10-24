extends Node2D
# A patch of ground that hurts: poison pools, scorching sand. It shows a warning ring for a moment,
# then turns dangerous for a few seconds.

var kind := "poison"
var radius := 28.0
var warn := 0.9
var life := 6.0
var _t := 0.0
var _hit_cd := 0.0

const COLORS := {
	"poison": [Color(0.45, 0.9, 0.3), Color(0.2, 0.5, 0.15)],
	"sand": [Color(0.95, 0.8, 0.4), Color(0.6, 0.45, 0.2)],
	"fire": [Color(1.0, 0.6, 0.25), Color(0.7, 0.2, 0.1)],
}


func _ready() -> void:
	z_index = -3
	add_to_group("hazards")
	if kind == "poison":
		var light := PointLight2D.new()
		light.texture = load("res://pixel_art.gd").light()
		light.color = Color(0.5, 1.0, 0.4)
		light.energy = 0.5
		light.texture_scale = radius / 36.0
		add_child(light)


func _process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()
	if _t < warn:
		return
	_hit_cd -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and _hit_cd <= 0.0 and player.global_position.distance_to(global_position) < radius:
		_hit_cd = 0.7
		if kind == "poison":
			player.call("apply_poison", 3.0)
		player.call("hurt", 1, global_position)


func _draw() -> void:
	var cols: Array = COLORS.get(kind, COLORS["poison"])
	var main: Color = cols[0]
	var dark: Color = cols[1]
	if _t < warn:
		var a := 0.35 + 0.25 * sin(_t * 18.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(main, a + 0.3), 2.0)
		draw_circle(Vector2.ZERO, radius, Color(main, a * 0.25))
		return
	var fade := clampf(life / 1.2, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(dark, 0.55 * fade))
	draw_circle(Vector2.ZERO, radius * 0.82, Color(main, 0.4 * fade))
	for k in 6:
		var a := TAU * k / 6.0 + _t * 0.6
		var r := radius * (0.35 + 0.35 * fmod(_t * 0.7 + k * 0.17, 1.0))
		draw_circle(Vector2(cos(a), sin(a)) * r, 2.5, Color(main.lightened(0.4), 0.7 * fade))
