extends "res://area.gd"
# The old cave. Floors 1 and 2 are full of ordinary monsters, with chests and ore to find.
# Floor 3 is the boss chamber: just the King Slime, an arena, and a legendary prize.

const PixelArt := preload("res://pixel_art.gd")
const DecorScript := preload("res://decor.gd")
const Data := preload("res://dungeon_data.gd")
const FLOOR := [0, 0, 0, 0, 1]
const WALL := 57
const LADDER := 63
const DOOR_ROWS := Vector2i(10, 13) # tile rows of the openings in the side walls
const CHEST_CLOSED := 89
const CHEST_OPEN := 90
const BOSS_SPOT := Vector2i(21, 11)

var dungeon_id := "cave"
var dungeon: Dictionary
var theme: Dictionary
var boss: Dictionary # this floor's boss, if it is a boss room
var floor_no := 1
var data: Dictionary
var royal_chest: Node2D
var royal_light: PointLight2D
var stairs := false # is there a way down on this floor?
var gate_body: StaticBody2D # blocks the king chamber's east gap until he is beaten


func _ready() -> void:
	map_w = 30
	map_h = 22
	dungeon_id = GameState.dungeon if Data.DUNGEONS.has(GameState.dungeon) else "cave"
	dungeon = Data.DUNGEONS[dungeon_id]
	floor_no = GameState.cave_floor
	data = dungeon.floors[floor_no]
	theme = Data.THEMES[data.get("theme", "cave")]
	boss = data.get("boss", {})
	stairs = data.get("stairs", false) or (data.get("stairs_after_boss", false) and _boss_beaten())
	begin(DUNGEON)
	use_daylight = false
	canvas_mod.color = data.light
	ground.modulate = theme.ground
	_build_ground()
	_build_floor_art()
	_build_walls()
	_build_rocks()
	var ore: Array = data.ore
	for i in ore.size():
		add_ore(ore[i], 12 if i % 2 == 0 else 13)
	if data.has("chest"):
		_build_chest()
	if data.get("boss_gate", false):
		_build_boss_gate()
	if data.get("arena", false):
		_build_arena()
	_spawn_enemies()

	var spawn := Vector2(36, 11 * 16 + 12)
	if GameState.next_spawn == "up":
		spawn = Vector2((map_w - 3) * 16, 11 * 16 + 12)
	GameState.next_spawn = ""
	spawn_player(spawn)
	finish("%s  |  Space/X: sword  Shift: dash  Q: potion  E: eat" % data.name)
	_announce()


func _boss_beaten() -> bool:
	return not boss.is_empty() and GameState.flags.get(boss.flag, false)


# Paints the floor of themed dungeons over the plain tiles.
func _build_floor_art() -> void:
	var tex: Texture2D = null
	var gap: Texture2D = null
	match theme.floor:
		"ice":
			tex = PixelArt.ice_floor(28, 19)
			gap = PixelArt.ice_floor(1, 3)
		"sand":
			tex = PixelArt.sandstone_floor(28, 19)
			gap = PixelArt.sandstone_floor(1, 3)
		"wood":
			tex = PixelArt.plank_floor(28, 19)
			gap = PixelArt.plank_floor(1, 3)
		"mud":
			tex = PixelArt.mud_floor(28, 19)
			gap = PixelArt.mud_floor(1, 3)
		_:
			return
	_sprite_at(tex, Vector2(16, 32), -9)
	_sprite_at(gap, Vector2(0, 160), -9)
	if stairs or data.get("stairs_after_boss", false):
		_sprite_at(gap, Vector2((map_w - 1) * 16, 160), -9)


func _boss_alive() -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("boss"):
			return true
	return false


func music_for() -> String:
	if data.get("arena", false) and _boss_alive():
		return "mus_boss"
	return theme.music


func ambient_mode() -> String:
	return theme.ambient


func ambience_for() -> String:
	return theme.ambience


func _announce() -> void:
	if not boss.is_empty():
		if _boss_beaten():
			hud.toast(boss.quiet)
		else:
			Audio.sfx("roar")
			hud.toast(boss.announce)
	elif data.has("toast"):
		hud.toast(data.toast)


func _area_process(_delta: float) -> void:
	if traveling:
		return
	var x := player.global_position.x
	if x < 8.0:
		if floor_no == 1:
			GameState.last_dungeon = GameState.dungeon
			GameState.dungeon = "cave"
			travel(dungeon.exit_scene, dungeon.exit_spawn)
		else:
			GameState.cave_floor = floor_no - 1
			travel(CAVE_SCENE, "up")
	elif stairs and x > map_w * 16 - 12:
		GameState.cave_floor = floor_no + 1
		travel(CAVE_SCENE, "down")


# ---------- map ----------

func _build_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5 + floor_no
	for y in map_h:
		for x in map_w:
			set_tile(x, y, FLOOR[rng.randi() % FLOOR.size()])
	for x in map_w:
		set_tile(x, 0, WALL)
		set_tile(x, 1, WALL)
		set_tile(x, map_h - 1, WALL)
	for y in map_h:
		set_tile(0, y, WALL)
		set_tile(map_w - 1, y, WALL)
	for y in range(DOOR_ROWS.x, DOOR_ROWS.y):
		set_tile(0, y, FLOOR[0])
		if stairs:
			set_tile(map_w - 1, y, FLOOR[0])
	if stairs:
		set_tile(map_w - 2, 11, LADDER)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	world.add_child(body)
	var w := map_w * 16
	var h := map_h * 16
	var top := DOOR_ROWS.x * 16
	var bottom := DOOR_ROWS.y * 16
	var rects := [
		Rect2(0, 0, w, 32), Rect2(0, h - 16, w, 16),
		Rect2(0, 0, 16, top), Rect2(0, bottom, 16, h - bottom),
	]
	if stairs or data.get("stairs_after_boss", false):
		rects.append(Rect2(w - 16, 0, 16, top))
		rects.append(Rect2(w - 16, bottom, 16, h - bottom))
	else:
		rects.append(Rect2(w - 16, 0, 16, h))
	if data.get("stairs_after_boss", false) and not stairs:
		gate_body = StaticBody2D.new()
		var gate_shape := CollisionShape2D.new()
		var gate_box := RectangleShape2D.new()
		gate_box.size = Vector2(16, bottom - top)
		gate_shape.shape = gate_box
		gate_shape.position = Vector2(w - 8, (top + bottom) / 2.0)
		gate_body.add_child(gate_shape)
		world.add_child(gate_body)
	for r in rects:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = r.size
		shape.shape = box
		shape.position = r.get_center()
		body.add_child(shape)


func _build_rocks() -> void:
	var rocks: Array = data.rocks
	var arena: bool = data.get("arena", false)
	for i in rocks.size():
		var t: Vector2i = rocks[i]
		var rock := Node2D.new()
		rock.position = Vector2(t.x * 16, (t.y + 1) * 16)
		if arena:
			# Stone pillars topped with a gargoyle.
			rock.add_child(Tiles.sprite(DUNGEON, 31, Vector2(0, -16)))
			rock.add_child(Tiles.sprite(DUNGEON, 19, Vector2(0, -32)))
		else:
			rock.add_child(Tiles.sprite(DUNGEON, 65 if i % 2 == 0 else 64, Vector2(0, -16)))
		rock.modulate = theme.rock
		world.add_child(rock)
		add_blocker(rock, Rect2(3, -10, 10, 10))


func _sprite_at(texture: Texture2D, pos: Vector2, z := 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.position = pos
	s.z_index = z
	world.add_child(s)
	return s


# The doorway at the east end of floor 2: gargoyles, a warning sign and a glowing red label.
func _build_boss_gate() -> void:
	for y in [9, 13]:
		var g := Node2D.new()
		g.position = Vector2((map_w - 2) * 16, (y + 1) * 16)
		g.add_child(Tiles.sprite(DUNGEON, 19, Vector2(0, -16)))
		world.add_child(g)
	var label := Label.new()
	label.text = "BOSS CHAMBER"
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("ff6b7b"))
	label.add_theme_color_override("font_outline_color", Color("2e2233"))
	label.add_theme_constant_override("outline_size", 3)
	label.position = Vector2((map_w - 5) * 16 - 4, 8 * 16 + 4)
	label.z_index = 30
	world.add_child(label)
	add_sign(Vector2((map_w - 5) * 16 + 8, 14 * 16), [
		"WARNING: Beyond this gate lies the King Slime's chamber.",
		"No ordinary monsters there, just him. Heal up, bring potions and food, and don't stand still!",
	])


# The boss chamber: a glowing rune ring, torches along the wall, and gargoyle pillars.
func _build_arena() -> void:
	var centre := Vector2(BOSS_SPOT.x * 16 + 8, BOSS_SPOT.y * 16 + 8)
	var rune := PixelArt.rune_circle(150, 100)
	var rune_sprite := _sprite_at(rune, centre - Vector2(rune.get_width(), rune.get_height()) / 2.0, -8)
	rune_sprite.modulate = theme.get("rune", Color(0.6, 0.9, 1.5) if theme.floor == "ice" else Color.WHITE)
	for x in [3, 7, 11, 15, 19, 23, 27]:
		var t := Node2D.new()
		t.set_script(DecorScript)
		t.kind = "torch"
		t.position = Vector2(x * 16 + 4, 12)
		t.light_color = theme.torch
		world.add_child(t)
	# If the boss is already beaten, his chest is still here (open once you've claimed it).
	if _boss_beaten():
		_spawn_royal_chest(centre + Vector2(0, 14), false)
	if data.get("stairs_after_boss", false) and stairs:
		_build_stairs_extras()


func _build_stairs_extras() -> void:
	var label := Label.new()
	label.text = boss.get("stairs_label", "STAIRS")
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", boss.get("stairs_color", Color("a8e4ff")))
	label.add_theme_color_override("font_outline_color", Color("2e2233"))
	label.add_theme_constant_override("outline_size", 3)
	label.position = Vector2((map_w - 5) * 16 - 2, 8 * 16 + 4)
	label.z_index = 30
	world.add_child(label)
	var glow := PointLight2D.new()
	glow.texture = PixelArt.light()
	glow.color = Color(0.6, 0.85, 1.0)
	glow.texture_scale = 1.4
	glow.energy = 0.9
	glow.position = Vector2((map_w - 2) * 16 + 8, 11 * 16 + 8)
	world.add_child(glow)
	add_sign(Vector2((map_w - 5) * 16 + 8, 14 * 16), boss.get("stairs_sign", ["A stairway leads down."]))


# Called the moment the boss falls, if his death opens the way down: the east wall opens onto stairs.
func _open_stairs() -> void:
	if stairs:
		return
	stairs = true
	if gate_body:
		gate_body.queue_free()
		gate_body = null
	for y in range(DOOR_ROWS.x, DOOR_ROWS.y):
		set_tile(map_w - 1, y, FLOOR[0])
	set_tile(map_w - 2, 11, LADDER)
	_build_stairs_extras()


# ---------- chests ----------

func _build_chest() -> void:
	var c: Dictionary = data.chest
	var t: Vector2i = c.tile
	var chest := Node2D.new()
	chest.position = Vector2(t.x * 16 + 8, (t.y + 1) * 16)
	var looted: bool = GameState.flags.get(c.flag, false)
	var sprite := Tiles.sprite(DUNGEON, CHEST_OPEN if looted else CHEST_CLOSED, Vector2(-8, -16))
	chest.add_child(sprite)
	world.add_child(chest)
	add_blocker(chest, Rect2(-6, -8, 12, 8))
	add_interactable(chest, 24.0, func(): _open_chest(c, sprite))


func _open_chest(c: Dictionary, sprite: Sprite2D) -> void:
	if GameState.flags.get(c.flag, false):
		hud.toast("The chest is empty.")
		return
	GameState.flags[c.flag] = true
	Audio.sfx("chest")
	GameState.gold += c.gold
	GameState.potions = mini(GameState.potions + c.potions, GameState.POTION_CAP)
	sprite.region_rect = Tiles.region(CHEST_OPEN)
	hud.toast("Treasure! +%d gold, +%d potions" % [c.gold, c.potions])


# ---------- boss prize ----------

func _after_enemy_died(e: Node) -> void:
	if e.boss and not boss.is_empty() and e.kind == boss.kind:
		Audio.sfx("boss_defeat")
		hud.toast(boss.defeat)
		_spawn_royal_chest(e.position + Vector2(0, 8), true)
		if boss.get("opens_stairs", false):
			_open_stairs()


func _prize() -> Dictionary:
	return Data.PRIZES[boss.prize]


func _chest_flag() -> String:
	return _prize().flag


func _spawn_royal_chest(feet: Vector2, with_burst: bool) -> void:
	var prize := _prize()
	var style: String = prize.chest
	var opened: bool = GameState.flags.get(_chest_flag(), false)
	royal_chest = Node2D.new()
	royal_chest.position = feet
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.royal_chest(opened, style)
	sprite.centered = false
	sprite.position = Vector2(-14, -25)
	sprite.name = "Sprite"
	royal_chest.add_child(sprite)
	royal_light = PointLight2D.new()
	royal_light.texture = PixelArt.light()
	royal_light.color = PixelArt.chest_glow(style)
	royal_light.texture_scale = 1.4
	royal_light.energy = 0.9
	royal_light.position = Vector2(0, -12)
	royal_chest.add_child(royal_light)
	world.add_child(royal_chest)
	add_blocker(royal_chest, Rect2(-12, -10, 24, 10))
	if not opened:
		var sparkles := _sparkles()
		sparkles.color = PixelArt.chest_glow(style).lightened(0.4)
		royal_chest.add_child(sparkles)
	add_interactable(royal_chest, 28.0, _open_royal_chest)
	if with_burst:
		sprite.modulate = Color(3, 3, 3)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.8)


func _sparkles() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Sparkles"
	p.position = Vector2(0, -14)
	p.amount = 22
	p.lifetime = 1.6
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 22.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.8
	p.color = Color("ffe08a")
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 9.0
	p.z_index = 20
	return p


func _open_royal_chest() -> void:
	if GameState.flags.get(_chest_flag(), false):
		hud.toast("The chest is empty. You already have the treasure!")
		return
	var prize := _prize()
	hud.say(prize.title, prize.lines, _claim_prize)


func _claim_prize() -> void:
	var prize := _prize()
	Audio.sfx("prize")
	GameState.flags[prize.flag] = true
	if prize.has("set_flag"):
		GameState.flags[prize.set_flag] = true
	var weapon: String = prize.get("weapon", "")
	if weapon != "":
		if not weapon in GameState.weapons:
			GameState.weapons.append(weapon)
		GameState.weapon = weapon
	var armor: String = prize.get("armor", "")
	if armor != "":
		if not armor in GameState.armors:
			GameState.armors.append(armor)
		GameState.armor = armor
	var hat: String = prize.get("hat", "")
	if hat != "":
		if not hat in GameState.hats:
			GameState.hats.append(hat)
		GameState.hat = hat
	GameState.gold += prize.gold
	GameState.potions = mini(GameState.potions + prize.potions, GameState.POTION_CAP)
	GameState.equipment_changed.emit()
	var levels := GameState.add_xp(prize.xp)
	(royal_chest.get_node("Sprite") as Sprite2D).texture = PixelArt.royal_chest(true, prize.chest)
	var sparkles := royal_chest.get_node_or_null("Sparkles")
	if sparkles:
		sparkles.queue_free()
	hud.toast(prize.toast + ("  LEVEL UP! You are level %d." % GameState.level if levels > 0 else ""))
	GameState.save_game()


# ---------- monsters ----------

func _spawn_enemies() -> void:
	var spawns: Dictionary = data.spawns
	for kind in spawns:
		if not boss.is_empty() and kind == boss.kind and _boss_beaten():
			continue
		for t in spawns[kind]:
			spawn_enemy(kind, Vector2(t.x * 16 + 8, (t.y + 1) * 16))