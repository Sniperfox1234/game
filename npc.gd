extends Node2D
# A villager. Origin is at the feet. Shows a ! (new quest) or ? (ready to hand in) marker.

const Tiles := preload("res://tiles.gd")
const Quests := preload("res://quests.gd")
const DUNGEON := preload("res://assets/dungeon/tiles.png")

var npc_id := ""
var display_name := ""
var tile := 99
var _marker := ""
var _t := 0.0


func _ready() -> void:
	add_child(Tiles.sprite(DUNGEON, tile, Vector2(-8, -15)))


func _process(delta: float) -> void:
	_t += delta
	var m := Quests.marker(npc_id)
	if m != _marker or m != "":
		_marker = m
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-5, -1, 10, 2), Color(0, 0, 0, 0.25))
	if _marker != "":
		var font := ThemeDB.fallback_font
		var pos := Vector2(-4, -19 + sin(_t * 4.0) * 1.5)
		draw_string_outline(font, pos, _marker, HORIZONTAL_ALIGNMENT_CENTER, 8, 10, 3, Color.BLACK)
		draw_string(font, pos, _marker, HORIZONTAL_ALIGNMENT_CENTER, 8, 10, Color("f2c14e"))
