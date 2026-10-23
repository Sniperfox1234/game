extends Node2D
# A glowing orb that grants a temporary power-up when touched.
#   rage: +50% sword damage    swift: faster movement    aegis: blocks the next 3 hits    heart: heals

const PixelArt := preload("res://pixel_art.gd")

const NAMES := {
	"rage": "RAGE! Your attacks hit 50% harder for 15 seconds.",
	"swift": "SWIFT! You move much faster for 15 seconds.",
	"aegis": "AEGIS! A golden bubble blocks your next 3 hits.",
	"heart": "A healing heart! +3 HP.",
}

var kind := "rage"
var area: Node
var life := 14.0
var _t := randf() * 6.0
var _sprite := Sprite2D.new()


func _ready() -> void:
	z_index = 8
	_sprite.texture = PixelArt.orb(kind)
	_sprite.centered = false
	_sprite.position = Vector2(-8, -18)
	add_child(_sprite)
	var light := PointLight2D.new()
	light.texture = PixelArt.light()
	light.color = PixelArt.ORB_COLORS[kind].lightened(0.3)
	light.texture_scale = 0.55
	light.energy = 0.8
	light.position = Vector2(0, -10)
	add_child(light)


func _process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	_sprite.position.y = -18.0 + sin(_t * 4.0) * 2.0
	_sprite.visible = life > 3.0 or int(life * 6.0) % 2 == 0
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(global_position + Vector2(0, -4)) < 12.0:
		GameState.add_buff(kind)
		if area:
			area.hud.toast(NAMES[kind], PixelArt.ORB_COLORS[kind].lightened(0.4))
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-5, -1, 10, 2), Color(0, 0, 0, 0.25))
