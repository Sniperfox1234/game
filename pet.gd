extends CharacterBody2D
# The player's companion. Follows you around and fights nearby enemies. Can't be hurt.
#   dog:   runs in and bites
#   bat:   flits around enemies, quick small bites
#   ghost: floats back and fires spirit bolts
# Damage grows with the player's level. Origin is at the feet.

const Tiles := preload("res://tiles.gd")
const DUNGEON := preload("res://assets/dungeon/tiles.png")
const BoltScript := preload("res://bolt.gd")

const KINDS := {
	"dog": {"tile": 120, "name": "Biscuit", "speed": 85.0, "bite_cd": 0.7},
	"bat": {"tile": 124, "name": "Flit", "speed": 105.0, "bite_cd": 0.45},
	"ghost": {"tile": 121, "name": "Boo", "speed": 60.0, "bite_cd": 1.2},
}
const ENGAGE_RADIUS := 110.0 # how far from the player it will go after an enemy
const FOLLOW_GAP := 26.0
const TELEPORT_DIST := 240.0

var kind := "dog"
var sprite := Sprite2D.new()
var attack_cd := 0.0
var t := randf() * 10.0
var hearts := 0.0
var _ignoring_player := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0 if kind == "ghost" else 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	shape.position = Vector2(0, -3)
	add_child(shape)
	sprite.texture = DUNGEON
	sprite.region_enabled = true
	sprite.region_rect = Tiles.region(KINDS[kind].tile)
	sprite.centered = false
	sprite.position = Vector2(-8, -15)
	add_child(sprite)


func pet_name() -> String:
	return KINDS[kind].name


func pet_it(hud: Node) -> void:
	hearts = 1.0
	Audio.sfx("pet")
	hud.call("toast", "%s loves it!" % pet_name())


func _physics_process(delta: float) -> void:
	t += delta
	attack_cd = maxf(attack_cd - delta, 0.0)
	hearts = maxf(hearts - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if not _ignoring_player:
		_ignoring_player = true
		add_collision_exception_with(player)
	var to_player := player.global_position - global_position
	if to_player.length() > TELEPORT_DIST:
		global_position = player.global_position + Vector2(-12, 4)
		return

	var info: Dictionary = KINDS[kind]
	var target := _nearest_enemy(player.global_position)
	var move := Vector2.ZERO
	if target != null:
		move = _fight(target, info)
	elif to_player.length() > FOLLOW_GAP:
		var catch_up := 1.6 if to_player.length() > 90.0 else 1.0
		move = to_player.normalized() * info.speed * 0.8 * catch_up
	velocity = move
	move_and_slide()
	if move.x != 0.0:
		sprite.flip_h = move.x < 0.0

	var bob := 0.0
	if kind == "ghost" or kind == "bat":
		bob = sin(t * 5.0) * 2.0
	elif move != Vector2.ZERO:
		bob = -absf(sin(t * 12.0)) * 1.5
	sprite.position.y = -15.0 + bob
	if kind == "ghost":
		sprite.modulate = Color(1, 1, 1, 0.75)
	queue_redraw()


func _nearest_enemy(around: Vector2) -> Node2D:
	var best: Node2D = null
	var best_d := ENGAGE_RADIUS
	for e in get_tree().get_nodes_in_group("enemies"):
		var d: float = (e as Node2D).global_position.distance_to(around)
		if d < best_d:
			best = e
			best_d = d
	return best


func _fight(target: Node2D, info: Dictionary) -> Vector2:
	var center: Vector2 = target.call("hit_center")
	var to := center - global_position
	var dist := to.length()
	var dir := to / maxf(dist, 0.01)
	var dmg := GameState.pet_damage()
	if kind == "ghost":
		if attack_cd <= 0.0 and dist < 130.0:
			attack_cd = info.bite_cd
			var bolt := Node2D.new()
			bolt.set_script(BoltScript)
			bolt.friendly = true
			bolt.damage = dmg
			var lead: Vector2 = center + Vector2(target.get("velocity")) * (dist / 160.0)
			bolt.velocity = (lead - global_position).normalized() * 160.0
			bolt.position = position + Vector2(0, -8)
			get_parent().add_child(bolt)
		if dist < 55.0:
			return -dir * info.speed
		return dir * info.speed * 0.5 if dist > 95.0 else Vector2.ZERO
	var reach: float = float(target.get("radius")) + 6.0
	if dist < reach:
		if attack_cd <= 0.0:
			attack_cd = info.bite_cd
			target.call("hurt", dmg, global_position)
		return -dir * 10.0
	if kind == "bat":
		dir = (dir + dir.rotated(PI / 2.0) * sin(t * 8.0) * 0.6).normalized()
	return dir * info.speed


func _draw() -> void:
	draw_rect(Rect2(-4, -1, 8, 2), Color(0, 0, 0, 0.25))
	if hearts > 0.0:
		var y := -22.0 - (1.0 - hearts) * 8.0
		for off in [-4.0, 4.0]:
			draw_circle(Vector2(off - 1.5, y), 1.8, Color("ff6b8b", hearts))
			draw_circle(Vector2(off + 1.5, y), 1.8, Color("ff6b8b", hearts))
			draw_colored_polygon(PackedVector2Array([Vector2(off - 3.3, y + 0.5), Vector2(off + 3.3, y + 0.5), Vector2(off, y + 4.0)]), Color("ff6b8b", hearts))
