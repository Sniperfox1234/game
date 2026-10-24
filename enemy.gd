extends CharacterBody2D
# Every monster in the game. `kind` picks stats, sprite and behaviour. Origin is at the feet.

signal died(enemy: Node)
signal summon(kind: String, pos: Vector2)

const Tiles := preload("res://tiles.gd")
const DUNGEON := preload("res://assets/dungeon/tiles.png")
const BoltScript := preload("res://bolt.gd")
const SoftShadow := preload("res://soft_shadow.gd")

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
	# --- Sunscar desert and the tomb ---
	"scorpion": {"tile": 122, "hp": 8, "speed": 46.0, "radius": 7.0, "contact": 3, "aggro": 120.0, "ai": "charge", "gold": Vector2i(10, 15), "xp": 14, "tint": Color(1.25, 0.8, 0.4), "contact_effect": "poison"},
	"sandwisp": {"tile": 121, "hp": 7, "speed": 28.0, "radius": 7.0, "contact": 3, "aggro": 180.0, "ai": "wraith", "gold": Vector2i(12, 18), "xp": 16, "tint": Color(1.35, 1.1, 0.5), "bolt": {"effect": "slow", "speed": 80.0}},
	"mummy": {"tile": 111, "hp": 22, "speed": 24.0, "radius": 8.0, "contact": 4, "aggro": 120.0, "ai": "walk", "gold": Vector2i(20, 30), "xp": 26, "tint": Color(1.05, 0.98, 0.78), "scale": 1.15},
	"scarab": {"tile": 123, "hp": 5, "speed": 64.0, "radius": 6.0, "contact": 2, "aggro": 140.0, "ai": "flit", "gold": Vector2i(6, 10), "xp": 9, "tint": Color(1.3, 1.1, 0.5)},
	"cursed": {"tile": 84, "hp": 10, "speed": 30.0, "radius": 7.0, "contact": 2, "aggro": 160.0, "ai": "shoot", "gold": Vector2i(14, 20), "xp": 20, "tint": Color(1.25, 1.1, 0.6), "bolt": {"effect": "slow", "speed": 90.0}},
	"pharaoh": {"tile": 110, "hp": 130, "speed": 30.0, "radius": 17.0, "contact": 4, "aggro": 260.0, "ai": "pattern", "gold": Vector2i(220, 220), "xp": 400, "tint": Color(1.3, 1.1, 0.55), "scale": 2.3,
		"boss": {"attacks": ["slam", "fan", "slam", "fan"], "slam_r": 70.0, "ring_n": 12, "ring_speed": 80.0, "fan_n": 7, "fan_spread": 0.22, "fan_speed": 95.0,
			"effect": "slow", "dmg": 2, "cd": 3.6, "cd_enraged": 2.6, "summon": ["mummy", "scarab"], "thresholds": [0.66, 0.33]}},
	# --- Port Saltmere and the pirate cove ---
	"crab": {"tile": 120, "hp": 11, "speed": 36.0, "radius": 7.0, "contact": 3, "aggro": 110.0, "ai": "charge", "gold": Vector2i(10, 16), "xp": 16, "tint": Color(1.35, 0.6, 0.5)},
	"pirate": {"tile": 98, "hp": 14, "speed": 40.0, "radius": 7.0, "contact": 3, "aggro": 125.0, "ai": "charge", "gold": Vector2i(18, 28), "xp": 22, "tint": Color(0.85, 0.5, 0.5)},
	"parrot": {"tile": 124, "hp": 6, "speed": 74.0, "radius": 6.0, "contact": 2, "aggro": 150.0, "ai": "flit", "gold": Vector2i(8, 12), "xp": 12, "tint": Color(0.6, 1.3, 0.6)},
	"cannoneer": {"tile": 97, "hp": 16, "speed": 26.0, "radius": 8.0, "contact": 3, "aggro": 170.0, "ai": "shoot", "gold": Vector2i(22, 32), "xp": 26, "tint": Color(0.7, 0.7, 0.9), "bolt": {"speed": 60.0, "damage": 2, "fan": 3, "spread": 0.18}},
	"blackjaw": {"tile": 98, "hp": 150, "speed": 38.0, "radius": 16.0, "contact": 4, "aggro": 260.0, "ai": "pattern", "gold": Vector2i(260, 260), "xp": 450, "tint": Color(0.6, 0.42, 0.5), "scale": 2.2,
		"boss": {"attacks": ["charge", "fan", "slam", "charge"], "slam_r": 64.0, "ring_n": 10, "ring_speed": 85.0, "fan_n": 5, "fan_spread": 0.28, "fan_speed": 100.0,
			"effect": "", "dmg": 2, "cd": 3.2, "cd_enraged": 2.3, "charge_speed": 190.0, "summon": ["pirate", "parrot"], "thresholds": [0.6, 0.3]}},
	# --- Mistmere swamp and the witch's lair ---
	"bogslime": {"tile": 108, "hp": 10, "speed": 28.0, "radius": 7.0, "contact": 3, "aggro": 100.0, "ai": "hop", "gold": Vector2i(10, 16), "xp": 16, "tint": Color(0.55, 0.8, 0.35), "contact_effect": "poison"},
	"wisp": {"tile": 121, "hp": 8, "speed": 28.0, "radius": 7.0, "contact": 3, "aggro": 190.0, "ai": "wraith", "gold": Vector2i(14, 20), "xp": 20, "tint": Color(0.6, 1.4, 0.6), "bolt": {"effect": "poison", "speed": 75.0}},
	"zombie": {"tile": 87, "hp": 26, "speed": 24.0, "radius": 8.0, "contact": 4, "aggro": 110.0, "ai": "walk", "gold": Vector2i(22, 32), "xp": 28, "tint": Color(0.6, 1.0, 0.6), "contact_effect": "poison"},
	"bogdog": {"tile": 120, "hp": 12, "speed": 52.0, "radius": 7.0, "contact": 3, "aggro": 130.0, "ai": "charge", "gold": Vector2i(14, 20), "xp": 20, "tint": Color(0.5, 0.8, 0.5), "contact_effect": "poison"},
	"morwen": {"tile": 84, "hp": 140, "speed": 28.0, "radius": 15.0, "contact": 3, "aggro": 260.0, "ai": "pattern", "gold": Vector2i(300, 300), "xp": 500, "tint": Color(0.7, 1.35, 0.75), "scale": 2.3,
		"boss": {"attacks": ["blink", "pools", "fan", "pools"], "slam_r": 60.0, "ring_n": 10, "ring_speed": 75.0, "fan_n": 5, "fan_spread": 0.3, "fan_speed": 85.0,
			"effect": "poison", "dmg": 2, "cd": 3.0, "cd_enraged": 2.2, "summon": ["wisp", "bogslime"], "thresholds": [0.66, 0.33], "pools": 4}},
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
	"scorpion": "Pounces fast and its sting poisons. Keep moving, and drink a potion to cure the poison.",
	"sandwisp": "A drifting spark of the desert. Its sand bolts slow you down.",
	"mummy": "Slow and sturdy, wrapped in ancient bandages. Burn it, then back away.",
	"scarab": "A swarming beetle. Weak alone, but they come in numbers.",
	"cursed": "Keeps its distance and curses you with slowing bolts. Close in quickly.",
	"pharaoh": "Slams the sand and fires fans of slowing bolts. Calls mummies as it weakens. Watch the gold circle!",
	"crab": "A hard-shelled brute that scuttles in and pinches. Hit it from the side.",
	"pirate": "Charges with a cutlass. Dash aside as it flashes, then strike.",
	"parrot": "A fast, flitting pest that nips at you.",
	"cannoneer": "Fires a spread of heavy cannon shots. Dash through the gaps.",
	"blackjaw": "Charges, fires cannon volleys and slams the deck. Calls his crew at half health.",
	"bogslime": "A swamp slime whose touch poisons. Don't let it corner you.",
	"wisp": "A glowing ghost light that throws poison bolts. Fireballs pop it quickly.",
	"zombie": "A tough shambling corpse with a poisonous touch. Keep your distance.",
	"bogdog": "A fast hound that pounces and poisons. Dash sideways as it charges.",
	"morwen": "Blinks around the arena, drops pools of poison and fires bolts. Stay out of the green circles!",
	"frostslime": "A chilly slime. Its touch slows you down, so don't let it corner you.",
	"frostbat": "Fast and cold. Being bitten slows you, so kill it quickly.",
	"snowgob": "Tougher goblin that charges just like the others. Dash sideways, then strike!",
	"wraith": "Floats through walls and throws ice shards that slow you. Fireballs melt it nicely.",
	"yeti": "A towering brute with a lot of health. Hit, back away, repeat. Burn it!",
	"titan": "Slams the ground (get out of the red circle!) and fires fans of ice shards. Enrages at half health.",
}
const NAMES := {
	"scorpion": "Scorpion", "sandwisp": "Sand Wisp", "mummy": "Mummy", "scarab": "Scarab", "cursed": "Cursed Priest", "pharaoh": "The Pharaoh",
	"crab": "Rock Crab", "pirate": "Pirate", "parrot": "Parrot", "cannoneer": "Cannoneer", "blackjaw": "Captain Blackjaw",
	"bogslime": "Bog Slime", "wisp": "Will-o'-Wisp", "zombie": "Bog Zombie", "bogdog": "Bog Hound", "morwen": "Witch Morwen",
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
var poison_time := 0.0
var poison_tick := 0.0
var t := randf() * 10.0

var contact_effect := "" # what touching it does to you on top of damage: "slow" or "poison"
var bolt_speed := 75.0
var bolt_damage := 1
var bolt_effect := ""
var bolt_fan := 1
var bolt_spread := 0.2
var phase := 0
var atk_i := 0
var cur_atk := ""
var enraged := false
var slam_next := true
var ring_t := 0.0

var boss: bool:
	get:
		return kind in ["king", "titan", "pharaoh", "blackjaw", "morwen"]

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
	contact_effect = d.get("contact_effect", "slow" if d.get("slows", false) else "")
	var b: Dictionary = d.get("bolt", {})
	bolt_speed = b.get("speed", 75.0)
	bolt_damage = b.get("damage", 1)
	bolt_effect = b.get("effect", "")
	bolt_fan = b.get("fan", 1)
	bolt_spread = b.get("spread", 0.2)


func _ready() -> void:
	add_to_group("enemies")
	SoftShadow.attach(self, Vector2(radius * 2.0 + 3.0, radius * 0.8 + 2.0), Vector2(0, -1))
	if raider:
		add_to_group("raiders")
	collision_layer = 2
	collision_mask = 0 if (ai == "float" or ai == "wraith") else 1
	if ai == "pattern":
		cooldown = 2.0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius * 0.6
	shape.shape = circle
	shape.position = Vector2(0, -radius * 0.6)
	add_child(shape)

	sprite.texture = Tiles.smooth(DUNGEON)
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
	elif kind == "poison":
		poison_time = 4.0
		poison_tick = 0.8
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
		"pattern":
			move = _pattern_boss(delta, dir, awake)
			sprite.position.y = base_y - absf(sin(t * 3.0)) * 2.0 * scale_f
			if state == 20 or state == 21:
				tint = Color(2.0, 2.0, 2.0) if state == 20 else Color(1.6, 1.2, 1.2)
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
	if poison_time > 0.0:
		poison_time -= delta
		poison_tick -= delta
		tint = tint * Color(0.7, 1.3, 0.6)
		if poison_tick <= 0.0:
			poison_tick = 0.8
			hurt(1, global_position)
			if hp <= 0:
				return
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
	if ring_t > 0.0 or state == 1 or (ai == "pattern" and state == 20):
		queue_redraw()
	sprite.modulate = Color(2.0, 2.0, 2.0) if flash > 0.0 else tint
	hit_cd = maxf(hit_cd - delta, 0.0)
	if hit_cd <= 0.0 and dist < radius + 5.0:
		player.call("hurt", contact, global_position)
		if contact_effect == "slow":
			player.call("apply_slow", 2.0)
		elif contact_effect == "poison":
			player.call("apply_poison", 4.0)
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
		_volley(dir)
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
		_volley(dir, "slow")
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


# A boss that cycles through its attack list (slam, fan, charge, pools, blink). Driven by KINDS[kind].boss.
func _pattern_boss(delta: float, dir: Vector2, awake: bool) -> Vector2:
	var cfg: Dictionary = KINDS[kind].boss
	var thresholds: Array = cfg.thresholds
	while phase < thresholds.size() and float(hp) / max_hp <= thresholds[phase]:
		phase += 1
		enraged = true
		flash = 0.5
		Audio.sfx("roar")
		for k in cfg.summon:
			for i in 2:
				summon.emit(k, position + Vector2.from_angle(TAU * (i + phase * 0.37) / 2.0) * 46.0)
		summon.emit("orb", position + Vector2(-60, 50))
		summon.emit("orb", position + Vector2(60, 50))
	var rate := 1.45 if enraged else 1.0
	match state:
		20: # winding up an attack
			state_time -= delta
			if state_time <= 0.0:
				_execute_attack(cur_atk, dir, cfg)
			return Vector2.ZERO
		21: # charging
			state_time -= delta
			if state_time <= 0.0:
				state = 0
				cooldown = cfg.cd_enraged if enraged else cfg.cd
			return lock_dir * float(cfg.get("charge_speed", 190.0))
	if awake and cooldown <= 0.0:
		var attacks: Array = cfg.attacks
		cur_atk = attacks[atk_i % attacks.size()]
		atk_i += 1
		state = 20
		state_time = {"slam": 0.9, "fan": 0.5, "charge": 0.6, "pools": 0.7, "blink": 0.5}.get(cur_atk, 0.6)
		if enraged:
			state_time *= 0.75
		lock_dir = dir
		return Vector2.ZERO
	return dir * speed * rate if awake else Vector2.ZERO


func _execute_attack(atk: String, dir: Vector2, cfg: Dictionary) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var effect: String = cfg.effect
	var after_cd: float = cfg.cd_enraged if enraged else cfg.cd
	state = 0
	match atk:
		"slam":
			Audio.sfx("slam")
			ring_t = 0.4
			var radius: float = cfg.slam_r
			if player and global_position.distance_to(player.global_position) < radius:
				player.call("hurt", cfg.dmg, global_position)
				if effect == "slow":
					player.call("apply_slow", 2.0)
				elif effect == "poison":
					player.call("apply_poison", 4.0)
			for i in int(cfg.ring_n):
				_fire(Vector2.from_angle(TAU * i / float(cfg.ring_n) + t), float(cfg.ring_speed), false, effect, int(cfg.dmg))
		"fan":
			var n: int = cfg.fan_n
			for k in n:
				_fire(dir.rotated((k - (n - 1) / 2.0) * float(cfg.fan_spread)), float(cfg.fan_speed), false, effect, int(cfg.dmg))
			Audio.sfx("bolt")
		"charge":
			state = 21
			state_time = 0.5
			lock_dir = dir
			after_cd = 0.0
			Audio.sfx("dash")
		"pools":
			Audio.sfx("slam")
			var count: int = cfg.get("pools", 3)
			for i in count:
				var spot := position
				if player:
					spot = player.global_position + Vector2.from_angle(TAU * i / float(count) + randf()) * (0.0 if i == 0 else randf_range(26.0, 60.0))
				summon.emit("hazard_poison", spot)
		"blink":
			Audio.sfx("dash")
			if player:
				var target := player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 150.0)
				position = target.clamp(Vector2(48, 64), Vector2(432, 320))
			flash = 0.3
			ring_t = 0.3
			for i in 8:
				_fire(Vector2.from_angle(TAU * i / 8.0 + t), 70.0, false, effect, int(cfg.dmg))
	if state != 21:
		cooldown = after_cd


# This monster's own bolts: speed, damage, how many in a fan, and any effect, from its stats.
func _volley(dir: Vector2, default_effect := "") -> void:
	var effect := bolt_effect if bolt_effect != "" else default_effect
	for k in bolt_fan:
		var a := (k - (bolt_fan - 1) / 2.0) * bolt_spread
		_fire(dir.rotated(a), bolt_speed, false, effect, bolt_damage)


func _fire(dir: Vector2, bolt_speed: float, frost := false, effect := "", damage := 1) -> void:
	var bolt := Node2D.new()
	bolt.set_script(BoltScript)
	if effect != "":
		bolt.effect = effect
	elif frost:
		bolt.effect = "slow"
	bolt.damage = damage
	bolt.velocity = dir * bolt_speed
	bolt.position = position + Vector2(0, -8.0 * scale_f)
	get_parent().add_child(bolt)
	Audio.sfx("bolt", 0.08)


func _draw() -> void:
	if boss:
		var w := 32.0 if kind == "king" else 56.0
		var top := -36.0 if kind == "king" else -70.0
		if ai == "pattern":
			top = -62.0
		draw_rect(Rect2(-w / 2.0 - 1, top, w + 2, 5), Color("2e2233"))
		draw_rect(Rect2(-w / 2.0, top + 1, w * clampf(float(hp) / max_hp, 0.0, 1.0), 3), Color("e84a5f"))
	if ai == "pattern":
		var cfg: Dictionary = KINDS[kind].boss
		if state == 20 and cur_atk == "slam":
			var a := 0.35 + 0.3 * sin(t * 20.0)
			var r: float = cfg.slam_r
			draw_arc(Vector2(0, -6), r, 0.0, TAU, 48, Color(1.0, 0.3, 0.3, a + 0.2), 2.0)
			draw_circle(Vector2(0, -6), r, Color(1.0, 0.2, 0.2, a * 0.25))
		if ring_t > 0.0:
			var u := 1.0 - ring_t / 0.4
			draw_arc(Vector2(0, -6), 10.0 + u * float(cfg.slam_r), 0.0, TAU, 48, Color(1.0, 0.95, 0.8, 1.0 - u), 4.0)
	if kind == "titan":
		if state == 1:
			# Red warning circle: get out before the slam lands.
			var a := 0.35 + 0.3 * sin(t * 20.0)
			draw_arc(Vector2(0, -6), SLAM_RADIUS, 0.0, TAU, 48, Color(1.0, 0.3, 0.3, a + 0.2), 2.0)
			draw_circle(Vector2(0, -6), SLAM_RADIUS, Color(1.0, 0.2, 0.2, a * 0.25))
		if ring_t > 0.0:
			var u := 1.0 - ring_t / 0.4
			draw_arc(Vector2(0, -6), 10.0 + u * SLAM_RADIUS, 0.0, TAU, 48, Color(0.8, 0.95, 1.0, 1.0 - u), 4.0)
