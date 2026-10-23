extends Node2D
# The town fountain: pixel-art basin with animated water jets. Origin is the basin's centre.

const PixelArt := preload("res://pixel_art.gd")
const FRAME_TIME := 0.11

var _sprite := Sprite2D.new()
var _frames: Array
var _t := 0.0


func _ready() -> void:
	_frames = PixelArt.fountain_frames()
	_sprite.texture = _frames[0]
	_sprite.centered = false
	_sprite.position = -PixelArt.fountain_origin()
	add_child(_sprite)


func _process(delta: float) -> void:
	_t += delta
	_sprite.texture = _frames[int(_t / FRAME_TIME) % _frames.size()]
