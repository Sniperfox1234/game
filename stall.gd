extends Node2D
# Market stall drawn from rectangles. Origin is the bottom-centre.


func _draw() -> void:
	draw_rect(Rect2(-13, -10, 26, 10), Color("8a6240"))
	draw_rect(Rect2(-13, -10, 26, 2), Color("6b4a2f"))
	draw_rect(Rect2(-11, -22, 2, 12), Color("6b4a2f"))
	draw_rect(Rect2(9, -22, 2, 12), Color("6b4a2f"))
	for i in 6:
		var c := Color("e86a6a") if i % 2 == 0 else Color("f5f5f5")
		draw_rect(Rect2(-14 + i * 5, -28, 5, 7), c)
	draw_circle(Vector2(-5, -11), 2.0, Color("ff7043"))
	draw_circle(Vector2(0, -11), 2.0, Color("f2c14e"))
	draw_circle(Vector2(5, -11), 2.0, Color("6abf69"))
