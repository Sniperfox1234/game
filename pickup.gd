extends Node2D
# A mushroom you can pick. Grows back the next day. Origin is the bottom-left of its tile.

const Tiles := preload("res://tiles.gd")
const TOWN := preload("res://assets/town/tiles.png")

var available := true
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Tiles.sprite(TOWN, 29, Vector2(0, -16))
	add_child(_sprite)


func is_available() -> bool:
	return available


func take() -> void:
	available = false
	_sprite.visible = false


func regrow() -> void:
	available = true
	_sprite.visible = true
