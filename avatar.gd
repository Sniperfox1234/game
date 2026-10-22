extends Node2D
# Placeholder chibi avatar drawn from rectangles, tinted by the creator's choices.


func _draw() -> void:
	draw_rect(Rect2(-10, 12, 20, 4), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(-8, 0, 16, 14), GameState.shirt_color)
	draw_rect(Rect2(-9, -16, 18, 17), GameState.skin_color)
	draw_rect(Rect2(-10, -19, 20, 8), GameState.hair_color)
	draw_rect(Rect2(-10, -12, 4, 7), GameState.hair_color)
	draw_rect(Rect2(6, -12, 4, 7), GameState.hair_color)
	draw_rect(Rect2(-5, -6, 3, 4), Color.BLACK)
	draw_rect(Rect2(2, -6, 3, 4), Color.BLACK)
