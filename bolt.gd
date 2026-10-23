extends Node2D
# A magic bolt fired by mages and the King Slime. Hurts the player on touch.

var velocity := Vector2.ZERO
var damage := 1
var life := 2.5


func _ready() -> void:
	z_index = 10


func _process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and global_position.distance_to(player.global_position + Vector2(0, -6)) < 7.0:
		player.call("hurt", damage, global_position - velocity.normalized() * 4.0)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.5, Color("5b2a8a"))
	draw_circle(Vector2.ZERO, 2.5, Color("b86bff"))
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE)
