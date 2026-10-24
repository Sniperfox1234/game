extends CharacterBody2D

signal died

const FireballScript := preload("res://fireball.gd")
const SoftShadow := preload("res://soft_shadow.gd")

const ATTACK_TIME := 0.18
const ATTACK_COOLDOWN := 0.35
const INVULN_TIME := 0.9
const REACH := 20.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.7
const DASH_SPEED := 210.0
const SPELL_COOLDOWN := 0.5

@export var speed: float = 70.0

var facing := Vector2.DOWN
var attack_left := 0.0
var cooldown := 0.0
var spell_cooldown := 0.0
var invuln := 0.0
var knock := Vector2.ZERO
var dash_left := 0.0
var dash_cooldown := 0.0
var dash_dir := Vector2.ZERO
var zaps: Array = [] # [from, to, time left] lightning bolts drawn after a Thunder Edge hit
var _tint := Color.WHITE
var slow_time := 0.0
var poison_time := 0.0
var _poison_tick := 0.0

@onready var avatar: Node2D = $Avatar


func _ready() -> void:
	add_to_group("player")
	SoftShadow.attach(self, Vector2(14, 5), Vector2(0, -1))


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = Vector2(signf(direction.x), 0.0)
		else:
			facing = Vector2(0.0, signf(direction.y))

	dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		Audio.sfx("dash", 0.05)
		dash_dir = direction if direction != Vector2.ZERO else facing
		dash_left = DASH_TIME
		dash_cooldown = DASH_COOLDOWN
		invuln = maxf(invuln, DASH_TIME + 0.1)

	knock = knock.move_toward(Vector2.ZERO, 500.0 * delta)
	if dash_left > 0.0:
		dash_left -= delta
		velocity = dash_dir * DASH_SPEED
	else:
		var run := speed * (1.35 if GameState.is_swift() else 1.0) * (0.55 if slow_time > 0.0 else 1.0)
		velocity = direction * run + knock
	move_and_slide()
	if direction.x != 0.0:
		avatar.scale.x = signf(direction.x)
	avatar.set_motion(direction != Vector2.ZERO, facing.y < 0.0)

	slow_time = maxf(slow_time - delta, 0.0)
	if poison_time > 0.0:
		poison_time -= delta
		_poison_tick -= delta
		if _poison_tick <= 0.0:
			_poison_tick = 1.0
			# Poison hurts but never finishes you off by itself.
			GameState.hp = maxi(GameState.hp - 1, 1)
			Audio.sfx("hurt", 0.1, -8.0)
	GameState.poison_time = poison_time
	cooldown = maxf(cooldown - delta, 0.0)
	spell_cooldown = maxf(spell_cooldown - delta, 0.0)
	if attack_left > 0.0:
		attack_left -= delta
		if attack_left <= 0.0:
			queue_redraw()
	if invuln > 0.0:
		invuln -= delta
		if invuln <= 0.0:
			avatar.modulate.a = 1.0
	_update_look(delta)


# Power-up looks: a red glow for Rage, a bubble for Aegis, and fading lightning bolts.
func _update_look(delta: float) -> void:
	var want := Color(1.0, 0.65, 0.6) if GameState.buff_rage > 0.0 else (Color(0.7, 1.0, 1.0) if GameState.buff_swift > 0.0 else Color.WHITE)
	if slow_time > 0.0:
		want = Color(0.65, 0.8, 1.3)
	if poison_time > 0.0:
		want = Color(0.7, 1.15, 0.65)
	var alpha := 1.0
	if invuln > 0.0:
		alpha = 0.4 if int(invuln * 20.0) % 2 == 0 else 1.0
	avatar.modulate = Color(want, alpha)
	var dirty := false
	for z in zaps:
		z[2] -= delta
		dirty = true
	zaps = zaps.filter(func(z): return z[2] > 0.0)
	if dirty or GameState.aegis_hits > 0 or _tint != want:
		queue_redraw()
	_tint = want


# Swings the equipped weapon in the facing direction. Does nothing while frozen.
func try_attack() -> void:
	if not is_physics_processing() or cooldown > 0.0:
		return
	var w := GameState.weapon_data()
	Audio.sfx("swing", 0.08)
	cooldown = ATTACK_COOLDOWN * float(w.cd)
	attack_left = ATTACK_TIME
	queue_redraw()
	var reach := _reach()
	var center := global_position + Vector2(0, -6) + facing * reach * 0.7
	var dmg := GameState.attack_damage()
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.call("hit_center").distance_to(center) < reach + float(e.get("radius")):
			hit_any = true
			e.call("hurt", dmg, global_position)
			if is_instance_valid(e):
				_apply_effect(w.effect, e, dmg)
	if hit_any and w.effect == "drain" and randf() < 0.3:
		GameState.heal(1)


func _apply_effect(effect: String, e: Node, dmg: int) -> void:
	match effect:
		"burn":
			e.call("apply_status", "burn")
		"poison":
			e.call("apply_status", "poison")
		"freeze":
			e.call("apply_status", "freeze")
		"shock":
			# Lightning jumps to the nearest other enemy within 60px.
			var best: Node = null
			var best_d := 60.0
			for o in get_tree().get_nodes_in_group("enemies"):
				if o == e:
					continue
				var d: float = o.call("hit_center").distance_to(e.call("hit_center"))
				if d < best_d:
					best = o
					best_d = d
			if best:
				zaps.append([to_local(e.call("hit_center")), to_local(best.call("hit_center")), 0.18])
				best.call("hurt", maxi(dmg - 1, 1), e.call("hit_center"))


func cast_fireball() -> bool:
	if not is_physics_processing() or spell_cooldown > 0.0 or GameState.spell < 1:
		return false
	if not GameState.use_mp(GameState.FIREBALL_COST):
		return false
	spell_cooldown = SPELL_COOLDOWN
	Audio.sfx("fireball", 0.05)
	var angles: Array[float] = []
	if GameState.spell < 2:
		angles.append(0.0)
	else:
		angles.append_array([-0.28, 0.0, 0.28])
	for a in angles:
		var f := Node2D.new()
		f.set_script(FireballScript)
		f.velocity = facing.rotated(a) * 150.0
		f.damage = GameState.fireball_damage()
		f.position = position + Vector2(0, -7) + facing * 8.0
		get_parent().add_child(f)
	return true


# Poison drains 1 HP a second for a few seconds (healing potions and the clinic cure it).
func apply_poison(seconds: float) -> void:
	if poison_time <= 0.0:
		_poison_tick = 1.0
	poison_time = maxf(poison_time, seconds)


func cure_poison() -> void:
	poison_time = 0.0


# Frost slows you to about half speed for a couple of seconds.
func apply_slow(seconds: float) -> void:
	if slow_time <= 0.0:
		Audio.sfx("freeze")
	slow_time = maxf(slow_time, seconds)


func hurt(amount: int, from: Vector2) -> void:
	if invuln > 0.0:
		return
	if GameState.aegis_hits > 0:
		# The Aegis bubble soaks up the hit.
		GameState.aegis_hits -= 1
		Audio.sfx("ice_shatter")
		invuln = 0.4
		knock = (global_position - from).normalized() * 60.0
		return
	GameState.hp = maxi(GameState.hp - maxi(amount - GameState.defense(), 1), 0)
	Audio.sfx("hurt", 0.05)
	invuln = INVULN_TIME
	knock = (global_position - from).normalized() * 140.0
	if GameState.hp <= 0:
		died.emit()


func _reach() -> float:
	return REACH + float(GameState.weapon_data().reach)


func _draw() -> void:
	if attack_left > 0.0:
		var w := GameState.weapon_data()
		var a := facing.angle()
		var half := float(w.arc)
		var col: Color = w.color
		var r := _reach() - 5.0
		var fancy: bool = w.effect != "" or int(w.dmg) >= 3
		if not fancy:
			draw_arc(Vector2(0, -6), r, a - half, a + half, 12, Color(col, 0.9), 2.0)
		else:
			draw_arc(Vector2(0, -6), r, a - half, a + half, 14, Color(col, 0.55), 5.0)
			draw_arc(Vector2(0, -6), r, a - half, a + half, 14, col.lightened(0.6), 2.0)
	for z in zaps:
		var from: Vector2 = z[0]
		var to: Vector2 = z[1]
		var prev := from
		for i in range(1, 5):
			var p := from.lerp(to, i / 4.0) + Vector2(randf_range(-3, 3), randf_range(-3, 3))
			if i == 4:
				p = to
			draw_line(prev, p, Color("ffe14a"), 2.0)
			draw_line(prev, p, Color.WHITE, 1.0)
			prev = p
	if GameState.aegis_hits > 0:
		draw_arc(Vector2(0, -8), 12.0, 0.0, TAU, 20, Color("ffd24a", 0.85), 1.5)
		draw_arc(Vector2(0, -8), 10.0, 0.0, TAU, 20, Color("ffffff", 0.25), 1.0)
