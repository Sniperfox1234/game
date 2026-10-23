extends Node2D
# A straw training dummy. It can't fight back; hit it with your sword, fireball or pet to test
# your damage. It also teaches a little: 1 XP per hit, up to 20 XP a day. It counts as an enemy
# so weapons and spells treat it like one, but it never dies.

const PixelArt := preload("res://pixel_art.gd")
const DAILY_XP := 20

var radius := 10.0
var boss := false
var area: Node
var total := 0
var _sprite := Sprite2D.new()


func _ready() -> void:
	add_to_group("enemies")
	_sprite.texture = PixelArt.training_dummy()
	_sprite.centered = false
	_sprite.offset = Vector2(-12, -33)
	add_child(_sprite)


func hit_center() -> Vector2:
	return global_position + Vector2(0, -16)


func apply_status(_kind: String) -> void:
	pass


func hurt(amount: int, from: Vector2) -> void:
	total += amount
	# Wobble away from the hit.
	var push := signf(global_position.x - from.x)
	var tw := create_tween()
	tw.tween_property(_sprite, "rotation", 0.25 * (push if push != 0.0 else 1.0), 0.05)
	tw.tween_property(_sprite, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC)
	_popup(str(amount))
	if GameState.flags.get("dummy_day", 0) != GameState.day:
		GameState.flags["dummy_day"] = GameState.day
		GameState.flags["dummy_xp"] = 0
	if int(GameState.flags.get("dummy_xp", 0)) < DAILY_XP:
		GameState.flags["dummy_xp"] = int(GameState.flags["dummy_xp"]) + 1
		if GameState.add_xp(1) > 0 and area:
			area.hud.toast("LEVEL UP! You are level %d." % GameState.level)
	elif int(GameState.flags.get("dummy_xp", 0)) == DAILY_XP and area:
		GameState.flags["dummy_xp"] = DAILY_XP + 1
		area.hud.toast("You've learned all you can from the dummy today. Come back tomorrow!")


func _popup(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color("ffd966"))
	l.add_theme_color_override("font_outline_color", Color("2e2233"))
	l.add_theme_constant_override("outline_size", 4)
	l.position = Vector2(randf_range(-8, 4), -40)
	l.z_index = 40
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 16.0, 0.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)
