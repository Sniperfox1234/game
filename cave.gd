extends Node2D
# Cave mouth drawn from rectangles. Origin is the bottom-centre; the opening is 20px wide.


func _draw() -> void:
	draw_rect(Rect2(-24, -30, 48, 30), Color("2e2233"))
	draw_rect(Rect2(-22, -28, 44, 28), Color("6e7a8f"))
	draw_rect(Rect2(-22, -28, 44, 4), Color("8c98ad"))
	draw_rect(Rect2(-10, -20, 20, 20), Color("2e2233"))
	draw_rect(Rect2(-8, -18, 16, 18), Color("0d0a12"))
	for p in [Vector2(-18, -14), Vector2(15, -10), Vector2(-16, -4), Vector2(12, -22)]:
		draw_rect(Rect2(p, Vector2(3, 2)), Color("55607a"))
