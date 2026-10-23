extends CharacterBody2D
# A hopping slime. The King Slime is the same thing, bigger, tougher and gold. Origin is at the feet.

signal died(enemy: Node)

const Tiles := preload("res://tiles.gd")
const DUNGEON := preload("res://assets/dungeon/tiles.png")
const SLIME_TILE := 108

var boss := false
var hp := 3
var speed := 26.0
var radius := 7.0
var contact := 1
var aggro := 90.0

var sprite := Sprite2D.new()
var base_color := Color.WHITE
var base_y := -14.0
var scale_f := 1.0
var knock := Vector2.ZERO
var wander := Vector2.ZERO
var wander_time := 0.0
var flash := 0.0
var hit_cd := 0.0
var t := randf() * 10.0


# Call before add_child.
func setup(is_boss: bool) -> void:
	boss = is_boss
	if boss:
		hp = 14
		speed = 34.0
		radius = 14.0
		contact = 2
		aggro = 150.0
		scale_f = 2.0
		base_color = Color("ffd24a")


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius * 0.6
	shape.shape = circle
	shape.position = Vector2(0, -radius * 0.6)
	add_child(shape)

	sprite.texture = DUNGEON
	sprite.region_enabled = true
	sprite.region_rect = Tiles.region(SLIME_TILE)
	sprite.centered = false
	sprite.scale = Vector2(scale_f, scale_f)
	base_y = -14.0 * scale_f
	sprite.position = Vector2(-8.0 * scale_f, base_y)
	sprite.modulate = base_color
	add_child(sprite)


func hit_center() -> Vector2:
	return global_position + Vector2(0, -radius * 0.6)


func hurt(amount: int, from: Vector2) -> void:
	hp -= amount
	flash = 0.15
	knock = (global_position - from).normalized() * (50.0 if boss else 120.0)
	if hp <= 0:
		died.emit(self)
		queue_free()


func _physics_process(delta: float) -> void:
	t += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var dir := Vector2.ZERO
	var dist := INF
	if player:
		var to := player.global_position - global_position
		dist = to.length()
		if dist < aggro:
			dir = to / maxf(dist, 0.01)
	if dir == Vector2.ZERO:
		wander_time -= delta
		if wander_time <= 0.0:
			wander_time = randf_range(1.0, 2.5)
			wander = Vector2.from_angle(randf() * TAU) if randf() < 0.6 else Vector2.ZERO
		dir = wander * 0.5

	var hop := absf(sin(t * 6.0))
	knock = knock.move_toward(Vector2.ZERO, 400.0 * delta)
	velocity = dir * speed * hop * 1.6 + knock
	move_and_slide()
	sprite.position.y = base_y - hop * 3.0 * scale_f

	flash = maxf(flash - delta, 0.0)
	sprite.modulate = Color(2.0, 2.0, 2.0) if flash > 0.0 else base_color
	hit_cd = maxf(hit_cd - delta, 0.0)
	if hit_cd <= 0.0 and dist < radius + 5.0:
		player.call("hurt", contact, global_position)
		hit_cd = 0.6


func _draw() -> void:
	var r := radius
	draw_rect(Rect2(-r * 0.9, -1, r * 1.8, 2), Color(0, 0, 0, 0.25))
