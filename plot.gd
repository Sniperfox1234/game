extends Node2D
# One patch of farmland: empty -> growing -> ripe.

enum State { EMPTY, GROWING, RIPE }

const GROW_DAYS := 3

var state := State.EMPTY
var age := 0
var highlighted := false


func interact() -> String:
	match state:
		State.EMPTY:
			if GameState.seeds <= 0:
				return "No seeds left!"
			GameState.seeds -= 1
			state = State.GROWING
			age = 0
			queue_redraw()
			return "Planted a seed."
		State.RIPE:
			GameState.crops += 1
			GameState.seeds += 1
			state = State.EMPTY
			queue_redraw()
			return "Harvested a crop!"
	return "Still growing..."


func advance_day() -> void:
	if state == State.GROWING:
		age += 1
		if age >= GROW_DAYS:
			state = State.RIPE
		queue_redraw()


func set_highlight(on: bool) -> void:
	if highlighted != on:
		highlighted = on
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-16, -16, 32, 32), Color("6b4a2f"))
	draw_rect(Rect2(-14, -14, 28, 28), Color("8a6240"))
	if state == State.GROWING:
		var h := 4 + age * 5
		draw_rect(Rect2(-2, 8 - h, 4, h), Color("4caf50"))
		draw_rect(Rect2(-6, 8 - h, 4, 3), Color("66cc66"))
		draw_rect(Rect2(2, 8 - h, 4, 3), Color("66cc66"))
	elif state == State.RIPE:
		draw_rect(Rect2(-2, -4, 4, 12), Color("4caf50"))
		draw_circle(Vector2(0, -6), 7, Color("ff7043"))
	if highlighted:
		draw_rect(Rect2(-16, -16, 32, 32), Color(1, 1, 1, 0.9), false, 1.0)
