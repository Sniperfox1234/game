extends Node2D
# A villager. Origin is at the feet. Shows a ! (new quest) or ? (ready to hand in) marker.
# With wander_r > 0 they stroll around their home spot, and stop when the player is close.

const Tiles := preload("res://tiles.gd")
const Quests := preload("res://quests.gd")
const DUNGEON := preload("res://assets/dungeon/tiles.png")
const SPEED := 12.0

var npc_id := ""
var display_name := ""
var tile := 99
var wander_r := 0.0

var _marker := ""
var _t := 0.0
var _sprite: Sprite2D
var _home := Vector2.ZERO
var _target := Vector2.ZERO
var _wait := 0.0


func _ready() -> void:
	_sprite = Tiles.sprite(DUNGEON, tile, Vector2(-8, -15))
	add_child(_sprite)
	_home = position
	_target = position
	_wait = randf_range(0.5, 3.0)


func _process(delta: float) -> void:
	_t += delta
	var m := Quests.marker(npc_id)
	if m != _marker or m != "":
		_marker = m
		queue_redraw()
	if wander_r > 0.0:
		_wander(delta)


func _wander(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(global_position) < 40.0:
		_sprite.flip_h = player.global_position.x < global_position.x
		return
	if position.distance_to(_target) < 1.5:
		_wait -= delta
		if _wait <= 0.0:
			_wait = randf_range(1.5, 4.5)
			_target = _home + Vector2.from_angle(randf() * TAU) * randf_range(0.0, wander_r)
		return
	var dir := (_target - position).normalized()
	position += dir * SPEED * delta
	_sprite.flip_h = dir.x < 0.0
	_sprite.position.y = -15.0 - absf(sin(_t * 10.0)) * 1.0


func _draw() -> void:
	draw_rect(Rect2(-5, -1, 10, 2), Color(0, 0, 0, 0.25))
	if _marker != "":
		var font := ThemeDB.fallback_font
		var pos := Vector2(-4, -19 + sin(_t * 4.0) * 1.5)
		draw_string_outline(font, pos, _marker, HORIZONTAL_ALIGNMENT_CENTER, 8, 10, 3, Color.BLACK)
		draw_string(font, pos, _marker, HORIZONTAL_ALIGNMENT_CENTER, 8, 10, Color("f2c14e"))
