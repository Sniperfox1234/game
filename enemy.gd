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
	"frostslime": {"tile": 108, "hp": 6, "speed": 28.0, "radius": 7.0, "contact": 2, "aggro": 95.0, "ai": "hop", "gold": Vector2i(6, 10), "xp": 8, "tint": Color(0.6, 0.9, 1.4), "slows": true},
	"frostbat": {"tile": 124, "hp": 4, "speed": 70.0, "radius": 6.0, "contact": 2, "aggro": 140.0, "ai": "flit", "gold": Vector2i(5, 8), "xp": 7, "tint": Color(0.6, 0.9, 1.4), "slows": true},
	"snowgob": {"tile": 112, "hp": 9, "speed": 40.0, "radius": 7.0, "contact": 3, "aggro": 115.0, "ai": "charge", "gold": Vector2i(9, 14), "xp": 12, "tint": Color(0.85, 0.95, 1.25)},
	"wraith": {"tile": 121, "hp": 6, "speed": 26.0, "radius": 7.0, "contact": 3, "aggro": 180.0, "ai": "wraith", "gold": Vector2i(12, 18), "xp": 15, "tint": Color(0.5, 0.85, 1.4)},
	"yeti": {"tile": 109, "hp": 24, "speed": 26.0, "radius": 10.0, "contact": 4, "aggro": 120.0, "ai": "walk", "gold": Vector2i(25, 35), "xp": 30, "tint": Color(0.9, 0.97, 1.2), "scale": 1.4},
	"titan": {"tile": 109, "hp": 90, "speed": 30.0, "radius": 18.0, "contact": 4, "aggro": 240.0, "ai": "titan", "gold": Vector2i(150, 150), "xp": 250, "tint": Color(0.65, 0.88, 1.35), "scale": 2.6},
	"king": {"tile": 108, "hp": 40, "speed": 34.0, "radius": 14.0, "contact": 2, "aggro": 170.0, "ai": "king", "gold": Vector2i(60, 60), "xp": 80},
}

# Shown in the town hall's bestiary once you have defeated one.
const TIPS := {
	"slime": "Hops toward you in groups. Weak alone, so don't get surrounded.",
	"bat": "Fast and weaves side to side. Wait for it to come to you, then swing.",
	"goblin": "Winds up (it flashes orange), then charges. Dash sideways just as it launches!",
	"wizard": "Keeps its distance and fires bolts. Close in quickly, or use fireballs.",
	"ghost": "Floats through walls, slow but relentless. Hits hard if it catches you.",
	"ogre": "Slow, tough and brutal. Hit it, back off, repeat. Frost Brand helps.",
	"king": "Fires rings of bolts and calls slimes at half health. Dash through the gaps!",
	"frostslime": "A chilly slime. Its touch slows you down, so don't let it corner you.",
	"frostbat": "Fast and cold. Being bitten slows you, so kill it quickly.",
	"snowgob": "Tougher goblin that charges just like the others. Dash sideways, then strike!",
	"wraith": "Floats through walls and throws ice shards that slow you. Fireballs melt it nicely.",
	"yeti": "A towering brute with a lot of health. Hit, back away, repeat. Burn it!",
	"titan": "Slams the ground (get out of the red circle!) and fires fans of ice shards. Enrages at half health.",
}
const NAMES := {
	"king": "King Slime", "frostslime": "Ice Slime", "frostbat": "Frost Bat", "snowgob": "Snow Goblin",
	"wraith": "Ice Wraith", "yeti": "Yeti", "titan": "Frost Titan",
}
const SLAM_RADIUS := 84.0

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

var slows := false # touching it slows you down
var enraged := false
var slam_next := true
var ring_t := 0.0

var boss: bool:
	get:
		return kind == "king" or kind == "titan"

var display_name: String:
	get:
		return NAMES.get(kind, String(kind).capitalize())


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
	if d.has("scale"):
		scale_f = d.scale
	if d.has("tint"):
		base_color = d.tint
	slows = d.get("slows", false)


func _ready() -> void:
	add_to_group("enemies")
	if raider:
		add_to_group("raiders")
	collision_layer = 2
	collision_mask = 0 if (ai == "float" or ai == "wraith") else 1
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
	if hp <= 0:
		Audio.sfx("enemy_die", 0.06)
	elif from != global_position:
		Audio.sfx("hit", 0.1)
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
		"wraith":
			move = _wraith(dir, dist, awake)
			sprite.position.y = base_y + sin(t * 3.0) * 2.0
			tint = Color(base_color.r, base_color.g, base_color.b, 0.65 + sin(t * 4.0) * 0.15)
		"titan":
			move = _titan(delta, dir, awake)
			sprite.position.y = base_y - absf(sin(t * 3.0)) * 2.0 * scale_f
			if state == 1 or state == 3:
				tint = Color(2.0, 2.0, 2.0)

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
	ring_t = maxf(ring_t - delta, 0.0)
	if ring_t > 0.0 or state == 1:
		queue_redraw()
	sprite.modulate = Color(2.0, 2.0, 2.0) if flash > 0.0 else tint
	hit_cd = maxf(hit_cd - delta, 0.0)
	if hit_cd <= 0.0 and dist < radius + 5.0:
		player.call("hurt", contact, global_position)
		if slows:
			player.call("apply_slow", 2.0)
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
		Audio.sfx("roar")
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


func _wraith(dir: Vector2, dist: float, awake: bool) -> Vector2:
	if not awake:
		return Vector2.ZERO
	if cooldown <= 0.0 and dist < 190.0:
		cooldown = 2.4
		_fire(dir, 70.0, true)
	if dist < 60.0:
		return -dir * speed
	if dist > 110.0:
		return dir * speed
	return dir.rotated(PI / 2.0) * speed * 0.4 * sin(t * 1.2)


# The Frost Titan: chases slowly, alternating a telegraphed ground slam with a fan of ice shards.
func _titan(delta: float, dir: Vector2, awake: bool) -> Vector2:
	if not enraged and hp <= max_hp / 2:
		enraged = true
		flash = 0.5
		state = 0
		cooldown = 1.0
		Audio.sfx("roar")
		for i in 3:
			summon.emit("frostslime", position + Vector2.from_angle(TAU * i / 3.0 + 0.4) * 44.0)
		summon.emit("orb", position + Vector2(-60, 50))
		summon.emit("orb", position + Vector2(60, 50))
	var rate := 1.5 if enraged else 1.0
	match state:
		1: # slam wind-up
			state_time -= delta
			if state_time <= 0.0:
				_slam()
				state = 0
				cooldown = 3.2 if enraged else 4.4
				slam_next = false
			return Vector2.ZERO
		3: # ice-shard wind-up
			state_time -= delta
			if state_time <= 0.0:
				for k in range(-2, 3):
					_fire(dir.rotated(k * 0.3), 85.0, true)
				state = 0
				cooldown = 3.0 if enraged else 4.2
				slam_next = true
			return Vector2.ZERO
	if awake and cooldown <= 0.0:
		if slam_next:
			state = 1
			state_time = 0.9 if not enraged else 0.7
		else:
			state = 3
			state_time = 0.5
		return Vector2.ZERO
	return dir * speed * rate if awake else Vector2.ZERO


func _slam() -> void:
	Audio.sfx("slam")
	ring_t = 0.4
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and global_position.distance_to(player.global_position) < SLAM_RADIUS:
		player.call("hurt", contact, global_position)
		player.call("apply_slow", 2.0)
	for i in 14:
		_fire(Vector2.from_angle(TAU * i / 14.0 + t), 75.0, true)


func _fire(dir: Vector2, bolt_speed: float, frost := false) -> void:
	var bolt := Node2D.new()
	bolt.set_script(BoltScript)
	bolt.frost = frost
	bolt.velocity = dir * bolt_speed
	bolt.position = position + Vector2(0, -8.0 * scale_f)
	get_parent().add_child(bolt)
	Audio.sfx("bolt", 0.08)


func _draw() -> void:
	draw_rect(Rect2(-radius * 0.9, -1, radius * 1.8, 2), Color(0, 0, 0, 0.25))
	if boss:
		var w := 32.0 if kind == "king" else 56.0
		var top := -36.0 if kind == "king" else -70.0
		draw_rect(Rect2(-w / 2.0 - 1, top, w + 2, 5), Color("2e2233"))
		draw_rect(Rect2(-w / 2.0, top + 1, w * clampf(float(hp) / max_hp, 0.0, 1.0), 3), Color("e84a5f"))
	if kind == "titan":
		if state == 1:
			# Red warning circle: get out before the slam lands.
			var a := 0.35 + 0.3 * sin(t * 20.0)
			draw_arc(Vector2(0, -6), SLAM_RADIUS, 0.0, TAU, 48, Color(1.0, 0.3, 0.3, a + 0.2), 2.0)
			draw_circle(Vector2(0, -6), SLAM_RADIUS, Color(1.0, 0.2, 0.2, a * 0.25))
		if ring_t > 0.0:
			var u := 1.0 - ring_t / 0.4
			draw_arc(Vector2(0, -6), 10.0 + u * SLAM_RADIUS, 0.0, TAU, 48, Color(0.8, 0.95, 1.0, 1.0 - u), 4.0)
