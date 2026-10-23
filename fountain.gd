extends Node2D
# The town fountain: a round stone basin with animated water jets. Origin is the centre.

const RADIUS := 34.0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _ellipse(r: float, color: Color, offset := Vector2.ZERO) -> void:
	draw_set_transform(offset, 0.0, Vector2(1.0, 0.72))
	draw_circle(Vector2.ZERO, r, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	_ellipse(RADIUS + 3.0, Color("2e2233"), Vector2(0, 4))
	_ellipse(RADIUS, Color("aab4c4"))
	_ellipse(RADIUS - 4.0, Color("d4dae4"))
	_ellipse(RADIUS - 7.0, Color("3b82c4"))
	# Ripples spreading out from the middle.
	for i in 3:
		var u := fposmod(_t * 0.5 + i / 3.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.72))
		draw_arc(Vector2.ZERO, 6.0 + u * (RADIUS - 14.0), 0.0, TAU, 32, Color(1, 1, 1, 0.5 * (1.0 - u)), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Centre pillar and bowl.
	draw_rect(Rect2(-5, -22, 10, 22), Color("2e2233"))
	draw_rect(Rect2(-4, -22, 8, 21), Color("aab4c4"))
	draw_rect(Rect2(-9, -26, 18, 5), Color("2e2233"))
	draw_rect(Rect2(-8, -26, 16, 4), Color("d4dae4"))
	# Water jets arcing out of the bowl.
	for i in 8:
		var a := TAU * i / 8.0
		for k in 4:
			var u := fposmod(_t * 0.9 + i * 0.125 + k * 0.05, 1.0)
			var x := cos(a) * u * 22.0
			var y := -28.0 - sin(u * PI) * 14.0 + u * 22.0 + sin(a) * u * 6.0
			draw_circle(Vector2(x, y), 1.3 - k * 0.2, Color(0.75, 0.9, 1.0, 0.9 - k * 0.2))
	for k in 5:
		var u := fposmod(_t * 1.4 + k * 0.2, 1.0)
		draw_circle(Vector2(sin(k * 2.0) * 1.5, -27.0 - u * 16.0), 1.4, Color(0.85, 0.95, 1.0, 1.0 - u))
