extends Node2D
# One patch of farmland: empty -> growing -> ripe.

enum State { EMPTY, GROWING, RIPE }

const Tiles := preload("res://tiles.gd")
const TOWN := preload("res://assets/town/tiles.png")
const SPROUT := 17
const BUSH := 5
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


func get_data() -> Array:
	return [state, age]


func set_data(data: Array) -> void:
	state = int(data[0]) as State
	age = int(data[1])
	queue_redraw()


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
	draw_rect(Rect2(-7, -7, 14, 14), Color("6b4a2f"))
	draw_rect(Rect2(-6, -6, 12, 12), Color("8a6240"))
	var spot := Rect2(-8, -8, 16, 16)
	if state == State.GROWING:
		var idx := SPROUT if age == 0 else BUSH
		draw_texture_rect_region(Tiles.smooth(TOWN), spot, Tiles.region(idx))
	elif state == State.RIPE:
		draw_texture_rect_region(Tiles.smooth(TOWN), spot, Tiles.region(BUSH))
		for p in [Vector2(-3, 0), Vector2(3, -2), Vector2(0, 3)]:
			draw_circle(p, 2.0, Color("ff7043"))
	if highlighted:
		draw_rect(spot, Color(1, 1, 1, 0.9), false, 1.0)
