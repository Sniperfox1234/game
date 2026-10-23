extends CharacterBody2D
# Every monster in the game. `kind` picks stats, sprite and behaviour. Origin is at the feet.

signal died(enemy: Node)
signal summon(kind: String, pos: Vector2)

const Tiles := preload("res://tiles.gd")
const DUNGEON := preload("res://assets/dungeon/tiles.png")
const BoltScript := preload("res://bolt.gd")

# ai: hop (slime), flit (bat), charge (goblin), shoot (mage), float (ghost), walk (ogre), king (boss).
const KINDS := {
	"slime": {"tile": 108, "hp": 3, "speed": 26.0, "radius": 7.0, "contact": 1, "aggro": 90.0, "ai": "hop", "gold": Vector2i(2, 4), "xp": 3},
	"bat": {"tile": 124, "hp": 2, "speed": 58.0, "radius": 6.0, "contact": 1, "aggro": 130.0, "ai": "flit", "gold": Vector2i(2, 3), "xp": 3},
	"goblin": {"tile": 112, "hp": 4, "speed": 38.0, "radius": 7.0, "contact": 2, "aggro": 110.0, "ai": "charge", "gold": Vector2i(4, 7), "xp": 6},
	"wizard": {"tile": 84, "hp": 3, "speed": 30.0, "radius": 7.0, "contact": 1, "aggro": 150.0, "ai": "shoot", "gold": Vector2i(5, 8), "xp": 8},
	"ghost": {"tile": 121, "hp": 4, "speed": 24.0, "radius": 7.0, "contact": 2, "aggro": 170.0, "ai": "float", "gold": Vector2i(5, 8), "xp": 8},
	"ogre": {"tile": 109, "hp": 9, "speed": 24.0, "radius": 9.0, "contact": 3, "aggro": 110.0, "ai": "walk", "gold": Vector2i(10, 15), "xp": 14},
	"king": {"tile": 108, "hp": 40, "speed": 34.0, "radius": 14.0, "contact": 2, "aggro": 170.0, "ai": "king", "gold": Vector2i(60, 60), "xp": 80},
}

var kind := "slime"
var raider := false # spawned by a night raid
var ai := "hop"
var hp := 3
var max_hp := 3
var speed := 26.0
var radius := 7.0
var contact := 1
var aggro := 90.0
var gold_range := Vector2i(2, 4)
var xp_value := 3
var scale_f := 1.0
var base_color := Color.WHITE

var sprite := Sprite2D.new()
var base_y := -14.0
var knock := Vector2.ZERO
var wander := Vector2.ZERO
var wander_time := 0.0
var flash := 0.0
var hit_cd := 0.0
var cooldown := 1.5
var state := 0 # charge: 0 walk, 1 wind-up, 2 dash. king: 0 chase, 1 telegraph.
var state_time := 0.0
var lock_dir := Vector2.ZERO
var summoned := false
var burn_time := 0.0
var burn_tick := 0.0
var slow_time := 0.0
var t := randf() * 10.0

var boss: bool:
	get:
		return kind == "king"


# Call before add_child.
func setup(k: String) -> void:
	kind = k
	var d: Dictionary = KINDS[k]
	ai = d.ai
	hp = d.hp
	max_hp = d.hp
	speed = d.speed
	radius = d.radius
	contact = d.contact
	aggro = d.aggro
	gold_range = d.gold
	xp_value = d.xp
	if k == "king":
		scale_f = 2.0
		base_color = Color("ffd24a")
	elif k == "ogre":
		scale_f = 1.25


func _ready() -> void:
	add_to_group("enemies")
	if raider:
		add_to_group("raiders")
	collision_layer = 2
	collision_mask = 0 if ai == "float" else 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius * 0.6
	shape.shape = circle
	shape.position = Vector2(0, -radius * 0.6)
	add_child(shape)

	sprite.texture = DUNGEON
	sprite.region_enabled = true
	sprite.region_rect = Tiles.region(KINDS[kind].tile)
	sprite.centered = false
	sprite.scale = Vector2(scale_f, scale_f)
	base_y = -15.0 * scale_f
	sprite.position = Vector2(-8.0 * scale_f, base_y)
	sprite.modulate = base_color
	add_child(sprite)


# Status effects from Flame Blade and Frost Brand weapons and from fireballs.
func apply_status(kind: String) -> void:
	if kind == "burn":
		burn_time = 3.0
		burn_tick = 0.6
	elif kind == "freeze":
		slow_time = 3.0


func hit_center() -> Vector2:
	return global_position + Vector2(0, -radius * 0.6)


func hurt(amount: int, from: Vector2) -> void:
	hp -= amount
	flash = 0.15
	var push := 30.0 if boss else (60.0 if kind == "ogre" else 120.0)
	knock = (global_position - from).normalized() * push
	if ai == "charge" and state == 1:
		state = 0
		cooldown = 1.0
	queue_redraw()
	if hp <= 0:
		died.emit(self)
		queue_free()


func _physics_process(delta: float) -> void:
	t += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var to := player.global_position - global_position
	var dist := to.length()
	var dir := to / maxf(dist, 0.01)
	var awake := dist < aggro
	cooldown -= delta
	var move := Vector2.ZERO
	var tint := base_color

	match ai:
		"hop":
			var hop := absf(sin(t * 6.0))
			move = (dir if awake else _wander(delta) * 0.5) * speed * hop * 1.6
			sprite.position.y = base_y - hop * 3.0 * scale_f
		"flit":
			var side := dir.rotated(PI / 2.0) * sin(t * 6.0) * 0.9
			move = ((dir + side).normalized() if awake else _wander(delta)) * speed
			sprite.position.y = base_y + sin(t * 14.0) * 1.5
		"charge":
			move = _charge(delta, dir, dist, awake)
			if state == 1:
				tint = Color(2.0, 1.3, 0.5)
		"shoot":
			move = _shoot(dir, dist, awake)
		"float":
			move = (dir if awake else _wander(delta) * 0.3) * speed
			sprite.position.y = base_y + sin(t * 3.0) * 2.0
			tint = Color(1, 1, 1, 0.6 + sin(t * 4.0) * 0.2)
		"walk":
			move = (dir if awake else _wander(delta) * 0.5) * speed
		"king":
			move = _king(delta, dir, awake)
			if state == 1:
				tint = Color(1.8, 1.8, 1.8)

	knock = knock.move_toward(Vector2.ZERO, 400.0 * delta)
	if slow_time > 0.0:
		slow_time -= delta
		move *= 0.4
		tint = tint * Color(0.55, 0.85, 1.4)
	velocity = move + knock
	move_and_slide()
	if burn_time > 0.0:
		burn_time -= delta
		burn_tick -= delta
		tint = tint * Color(1.5, 0.85, 0.5)
		if burn_tick <= 0.0:
			burn_tick = 0.6
			hurt(1, global_position)
			if hp <= 0:
				return

	flash = maxf(flash - delta, 0.0)
	sprite.modulate = Color(2.0, 2.0, 2.0) if flash > 0.0 else tint
	hit_cd = maxf(hit_cd - delta, 0.0)
	if hit_cd <= 0.0 and dist < radius + 5.0:
		player.call("hurt", contact, global_position)
		hit_cd = 0.6


func _wander(delta: float) -> Vector2:
	wander_time -= delta
	if wander_time <= 0.0:
		wander_time = randf_range(1.0, 2.5)
		wander = Vector2.from_angle(randf() * TAU) if randf() < 0.6 else Vector2.ZERO
	return wander


func _charge(delta: float, dir: Vector2, dist: float, awake: bool) -> Vector2:
	match state:
		1:
			state_time -= delta
			if state_time <= 0.0:
				state = 2
				state_time = 0.35
			return Vector2.ZERO
		2:
			state_time -= delta
			if state_time <= 0.0:
				state = 0
				cooldown = 1.6
			return lock_dir * 170.0
	if awake and dist < 85.0 and cooldown <= 0.0:
		state = 1
		state_time = 0.5
		lock_dir = dir
	return (dir if awake else _wander(delta) * 0.4) * speed


func _shoot(dir: Vector2, dist: float, awake: bool) -> Vector2:
	if not awake:
		return Vector2.ZERO
	if cooldown <= 0.0 and dist < 170.0:
		cooldown = 1.9
		_fire(dir, 75.0)
	if dist < 55.0:
		return -dir * speed
	if dist > 100.0:
		return dir * speed
	return dir.rotated(PI / 2.0) * speed * 0.5 * sin(t * 1.5)


func _king(delta: float, dir: Vector2, awake: bool) -> Vector2:
	# At half health the King calls three slimes to his side, once.
	if not summoned and hp <= max_hp / 2:
		summoned = true
		flash = 0.4
		for i in 3:
			summon.emit("slime", position + Vector2.from_angle(TAU * i / 3.0 + 0.5) * 30.0)
		# The chamber answers with power-up orbs for the hero.
		summon.emit("orb", position + Vector2(-48, 40))
		summon.emit("orb", position + Vector2(48, 40))
	if state == 1:
		state_time -= delta
		if state_time <= 0.0:
			state = 0
			cooldown = 3.0 if hp <= max_hp / 2 else 4.5
			var n := 14 if hp <= max_hp / 2 else 10
			for i in n:
				_fire(Vector2.from_angle(TAU * i / n + t), 70.0)
		return Vector2.ZERO
	if awake and cooldown <= 0.0:
		state = 1
		state_time = 0.55
	var hop := absf(sin(t * 5.0))
	sprite.position.y = base_y - hop * 3.0 * scale_f
	return (dir if awake else _wander(delta) * 0.4) * speed * hop * 1.6


func _fire(dir: Vector2, bolt_speed: float) -> void:
	var bolt := Node2D.new()
	bolt.set_script(BoltScript)
	bolt.velocity = dir * bolt_speed
	bolt.position = position + Vector2(0, -8.0 * scale_f)
	get_parent().add_child(bolt)


func _draw() -> void:
	draw_rect(Rect2(-radius * 0.9, -1, radius * 1.8, 2), Color(0, 0, 0, 0.25))
	if boss:
		var w := 32.0
		draw_rect(Rect2(-w / 2.0 - 1, -36, w + 2, 5), Color("2e2233"))
		draw_rect(Rect2(-w / 2.0, -35, w * clampf(float(hp) / max_hp, 0.0, 1.0), 3), Color("e84a5f"))
