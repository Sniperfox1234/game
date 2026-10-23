extends CharacterBody2D

signal died

const ATTACK_TIME := 0.18
const ATTACK_COOLDOWN := 0.35
const INVULN_TIME := 0.9
const REACH := 20.0

@export var speed: float = 70.0

var can_attack := false # areas with enemies turn this on
var facing := Vector2.DOWN
var attack_left := 0.0
var cooldown := 0.0
var invuln := 0.0
var knock := Vector2.ZERO

@onready var avatar: Node2D = $Avatar


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = Vector2(signf(direction.x), 0.0)
		else:
			facing = Vector2(0.0, signf(direction.y))
	knock = knock.move_toward(Vector2.ZERO, 500.0 * delta)
	velocity = direction * speed + knock
	move_and_slide()
	if direction.x != 0.0:
		avatar.scale.x = signf(direction.x)
	avatar.set_motion(direction != Vector2.ZERO, facing.y < 0.0)

	cooldown = maxf(cooldown - delta, 0.0)
	if attack_left > 0.0:
		attack_left -= delta
		if attack_left <= 0.0:
			queue_redraw()
	if invuln > 0.0:
		invuln -= delta
		avatar.modulate.a = 0.4 if int(invuln * 20.0) % 2 == 0 else 1.0
		if invuln <= 0.0:
			avatar.modulate.a = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if can_attack and is_physics_processing() and cooldown <= 0.0 and event.is_action_pressed("ui_accept"):
		_attack()


func _attack() -> void:
	cooldown = ATTACK_COOLDOWN
	attack_left = ATTACK_TIME
	queue_redraw()
	var center := global_position + Vector2(0, -6) + facing * REACH * 0.7
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.call("hit_center").distance_to(center) < REACH + float(e.get("radius")):
			e.call("hurt", GameState.damage, global_position)


func hurt(amount: int, from: Vector2) -> void:
	if invuln > 0.0:
		return
	GameState.hp = maxi(GameState.hp - amount, 0)
	invuln = INVULN_TIME
	knock = (global_position - from).normalized() * 140.0
	if GameState.hp <= 0:
		died.emit()


func _draw() -> void:
	if attack_left > 0.0:
		var a := facing.angle()
		draw_arc(Vector2(0, -6), 15.0, a - 0.9, a + 0.9, 10, Color(1, 1, 1, 0.9), 2.0)
