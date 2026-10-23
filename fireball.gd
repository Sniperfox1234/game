extends Node2D
# The player's fireball spell. Flies straight, bursts on the first enemy it touches, damages
# everything near the burst and sets it alight.

const Quests := preload("res://quests.gd")
const PixelArt := preload("res://pixel_art.gd")
const SPLASH_RADIUS := 26.0

var velocity := Vector2.ZERO
var damage := 2
var life := 1.4
var _t := 0.0
var _burst := -1.0 # time since exploding; -1 while still flying
var _trail: Array[Vector2] = []


func _ready() -> void:
	z_index = 10
	var light := PointLight2D.new()
	light.texture = PixelArt.light()
	light.color = Color(1.0, 0.6, 0.25)
	light.texture_scale = 0.6
	light.energy = 0.9
	add_child(light)


func _process(delta: float) -> void:
	_t += delta
	if _burst >= 0.0:
		_burst += delta
		if _burst > 0.3:
			queue_free()
		queue_redraw()
		return
	position += velocity * delta
	life -= delta
	_trail.push_front(position)
	if _trail.size() > 6:
		_trail.pop_back()
	if life <= 0.0:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(e.call("hit_center")) < float(e.get("radius")) + 4.0:
			_explode(e)
			return
	queue_redraw()


func _explode(first: Node) -> void:
	Audio.sfx("boom", 0.05)
	_burst = 0.0
	velocity = Vector2.ZERO
	var hit := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.call("hit_center"))
		if e == first or d < SPLASH_RADIUS + float(e.get("radius")):
			e.call("hurt", damage if e == first else maxi(damage - 1, 1), global_position)
			if is_instance_valid(e):
				e.call("apply_status", "burn")
			hit += 1
	if hit > 0:
		Quests.event("fireball")


func _draw() -> void:
	if _burst >= 0.0:
		var u := _burst / 0.3
		for k in 18:
			var a := TAU * k / 18.0
			var r := 4.0 + u * SPLASH_RADIUS
			var p := Vector2(cos(a), sin(a)) * r
			draw_rect(Rect2(p.x - 1.5, p.y - 1.5, 3, 3), Color("ff8a2a", 1.0 - u))
			var q := Vector2(cos(a + 0.2), sin(a + 0.2)) * r * 0.6
			draw_rect(Rect2(q.x - 1, q.y - 1, 2, 2), Color("ffd966", 1.0 - u))
		return
	# Fading trail of embers, then the flickering fireball itself.
	for i in _trail.size():
		var p := to_local(_trail[i])
		draw_circle(p, 3.0 - i * 0.4, Color("ff8a2a", 0.6 - i * 0.09))
	var flick := 0.5 * sin(_t * 30.0)
	draw_circle(Vector2.ZERO, 5.0 + flick, Color("c63a1a"))
	draw_circle(Vector2.ZERO, 3.8 + flick, Color("ff8a2a"))
	draw_circle(Vector2.ZERO, 2.2, Color("ffd966"))
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE)
