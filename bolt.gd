extends Node2D
# A magic bolt fired by mages and the King Slime. Hurts the player on touch.

var velocity := Vector2.ZERO
var damage := 1
var life := 2.5
var frost := false # ice shard: slows the player
var friendly := false # fired by the player's pet: hurts enemies instead of the player


func _ready() -> void:
	z_index = 10


func _process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if friendly:
		for e in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_to(e.call("hit_center")) < float(e.get("radius")) + 5.0:
				e.call("hurt", damage, global_position - velocity.normalized() * 6.0)
				queue_free()
				return
		queue_redraw()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and global_position.distance_to(player.global_position + Vector2(0, -6)) < 7.0:
		player.call("hurt", damage, global_position - velocity.normalized() * 4.0)
		if frost:
			player.call("apply_slow", 2.0)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var outer := Color("1f7a8c") if (friendly or frost) else Color("5b2a8a")
	var inner := Color("6be3ff") if (friendly or frost) else Color("b86bff")
	draw_circle(Vector2.ZERO, 3.5, outer)
	draw_circle(Vector2.ZERO, 2.5, inner)
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE)
