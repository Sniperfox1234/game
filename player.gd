extends CharacterBody2D

signal died

const ATTACK_TIME := 0.18
const ATTACK_COOLDOWN := 0.35
const INVULN_TIME := 0.9
const REACH := 20.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.7
const DASH_SPEED := 210.0

@export var speed: float = 70.0

var facing := Vector2.DOWN
var attack_left := 0.0
var cooldown := 0.0
var invuln := 0.0
var knock := Vector2.ZERO
var dash_left := 0.0
var dash_cooldown := 0.0
var dash_dir := Vector2.ZERO

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

	dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		dash_dir = direction if direction != Vector2.ZERO else facing
		dash_left = DASH_TIME
		dash_cooldown = DASH_COOLDOWN
		invuln = maxf(invuln, DASH_TIME + 0.1)

	knock = knock.move_toward(Vector2.ZERO, 500.0 * delta)
	if dash_left > 0.0:
		dash_left -= delta
		velocity = dash_dir * DASH_SPEED
	else:
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


# Swings the sword in the facing direction. Does nothing while frozen (dialogue, shop, fishing).
func try_attack() -> void:
	if not is_physics_processing() or cooldown > 0.0:
		return
	cooldown = ATTACK_COOLDOWN
	attack_left = ATTACK_TIME
	queue_redraw()
	var reach := _reach()
	var center := global_position + Vector2(0, -6) + facing * reach * 0.7
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.call("hit_center").distance_to(center) < reach + float(e.get("radius")):
			e.call("hurt", GameState.damage, global_position)


func hurt(amount: int, from: Vector2) -> void:
	if invuln > 0.0:
		return
	GameState.hp = maxi(GameState.hp - maxi(amount - GameState.defense(), 1), 0)
	invuln = INVULN_TIME
	knock = (global_position - from).normalized() * 140.0
	if GameState.hp <= 0:
		died.emit()


# The legendary Slimeblade, won from the King Slime, reaches further.
func _reach() -> float:
	return REACH + (7.0 if GameState.flags.get("slimeblade", false) else 0.0)


func _draw() -> void:
	if attack_left > 0.0:
		var a := facing.angle()
		if GameState.flags.get("slimeblade", false):
			draw_arc(Vector2(0, -6), _reach() - 5.0, a - 1.1, a + 1.1, 14, Color("5de08a", 0.9), 4.0)
			draw_arc(Vector2(0, -6), _reach() - 5.0, a - 1.1, a + 1.1, 14, Color("d8ffe8"), 2.0)
		else:
			draw_arc(Vector2(0, -6), 15.0, a - 0.9, a + 0.9, 10, Color(1, 1, 1, 0.9), 2.0)
