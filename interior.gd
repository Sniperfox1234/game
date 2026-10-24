extends "res://area.gd"
# The inside of a shop. Walk in through a door in town; the room loads as its own small map.
# Walk back out through the doorway at the bottom to return to the street.

const NpcScript := preload("res://npc.gd")
const PixelArt := preload("res://pixel_art.gd")
const DecorScript := preload("res://decor.gd")
const Weapons := preload("res://weapons.gd")
const RegionArt := preload("res://region_art.gd")

const Enemy := preload("res://enemy.gd")
const DummyScript := preload("res://dummy.gd")
const SKIN := ["f8d8b8", "f1c27d", "e0ac69", "c68642", "8d5524", "5c3a1e"]
const HAIR := ["1a1a1a", "4a2c17", "8b5a2b", "d9b44a", "c0392b", "6c8ebf"]
const SHIRT := ["4f9dde", "e86a6a", "6abf69", "f2c14e", "a66cd8", "f5f5f5"]

var W := 20 # room size in tiles; the town hall is bigger than the shops
var H := 14
const COUNTER_TILES := 8
const COUNTER_POS := Vector2(96, 96) # top-left, in px
var DOORWAY := Vector2i(9, 11) # tile columns of the gap in the bottom wall

# floor tiles are picked at random from the list; walls use the dungeon sheet's brick.
const ROOMS := {
	"smithy": {
		"title": "Tilda's Smithy", "floor": [0], "wall": 57, "wall_top": 40, "tint": Color(0.72, 0.64, 0.62),
		"keeper_id": "tilda", "keeper_name": "Tilda the Smith", "keeper_tile": 98,
		"greeting": "Welcome to my smithy! Fresh steel, still warm from the forge. See anything you like?",
	},
	"study": {
		"title": "Merlo's Study", "floor": [0], "wall": 57, "wall_top": 40, "tint": Color(0.6, 0.58, 0.86),
		"keeper_id": "merlo", "keeper_name": "Merlo the Wise", "keeper_tile": 84,
		"greeting": "Ah, a visitor! Magic is just physics with better manners. Care to learn a spell?",
	},
	"bakery": {
		"title": "Finn's Bakery", "floor": [0], "wall": 57, "wall_top": 40, "tint": Color(1.0, 0.95, 0.88),
		"keeper_id": "finn", "keeper_name": "Baker Finn", "keeper_tile": 88,
		"greeting": "Fresh from the oven! Pull up a chair and eat in, hero. Everything's warm.",
	},
	"hall": {
		"title": "Mossbrook Town Hall", "w": 28, "h": 19, "floor": [0], "wall": 57, "wall_top": 40, "tint": Color(1.0, 0.98, 0.96),
	},
	"armory": {
		"title": "Brann's Armory", "floor": [0, 0, 0, 0, 0, 0, 0, 1], "wall": 57, "wall_top": 40, "tint": Color(0.68, 0.66, 0.8),
		"keeper_id": "brann", "keeper_name": "Armorer Brann", "keeper_tile": 87,
		"greeting": "Welcome to my armory! Hats for style, armor for survival. Take a look!",
	},
	"throne": {
		"title": "The Throne Room", "w": 22, "h": 16, "floor": [0], "wall": 57, "wall_top": 40, "tint": Color(1.0, 0.95, 0.9),
	},
	"banquet": {
		"title": "The Banquet Hall", "w": 24, "h": 15, "floor": [0], "wall": 57, "wall_top": 40, "tint": Color(1.0, 0.93, 0.82),
		"keeper_id": "bastien", "keeper_name": "Chef Bastien", "keeper_tile": 88,
		"greeting": "Welcome to the royal table! Every dish fit for a king, and priced for a hero.",
	},
	"royal_armory": {
		"title": "The Royal Armoury", "floor": [0], "wall": 57, "wall_top": 40, "tint": Color(0.75, 0.72, 0.92),
		"keeper_id": "royce", "keeper_name": "Armourer Royce", "keeper_tile": 87,
		"greeting": "The finest steel in the realm, forged for the Crown. Only the proven may carry it.",
	},
	"butcher": {
		"title": "Gunnar's Butchery", "floor": [53, 53, 53, 53, 53, 49], "wall": 57, "wall_top": 40, "tint": Color(1.0, 0.95, 0.88),
		"keeper_id": "gunnar", "keeper_name": "Butcher Gunnar", "keeper_tile": 98,
		"greeting": "Fresh meat, cut this morning! Nothing heals you like a good steak.",
	},
}

var room_id := "armory"
var room: Dictionary
var room_npcs := {}


func _ready() -> void:
	room_id = GameState.interior if GameState.interior in ROOMS else "armory"
	room = ROOMS[room_id]
	W = int(room.get("w", 20))
	H = int(room.get("h", 14))
	DOORWAY = Vector2i(floori(W / 2.0) - 1, floori(W / 2.0) + 1)
	map_w = W
	map_h = H
	begin(DUNGEON)
	use_daylight = false
	canvas_mod.color = room.tint
	_build_ground()
	_build_walls()
	match room_id:
		"armory":
			_build_armory_props()
		"smithy":
			_build_smithy_props()
		"study":
			_build_study_props()
		"bakery":
			_build_bakery_props()
		"hall":
			_build_hall()
		"throne":
			_build_throne()
		"banquet":
			_build_banquet()
		"royal_armory":
			_build_royal_armory()
		_:
			_build_butcher_props()
	if room_id != "hall" and room_id != "throne":
		_build_counter()

	GameState.next_spawn = ""
	spawn_player(Vector2(W * 8.0, H * 16 - 26))
	_pin_camera()
	raids = false
	finish("Space: use stations and talk to people   |   Walk out the bottom door to leave" if room_id in ["hall", "throne"] else "Space: talk to the shopkeeper   |   Walk out the bottom door to leave")
	hud.toast(room.title)


func music_for() -> String:
	return "mus_castle" if room_id in ["throne", "banquet", "royal_armory"] else "mus_interior"


func _area_process(_delta: float) -> void:
	if not traveling and player.global_position.y > H * 16 - 10:
		GameState.interior = ""
		var back := GameState.interior_exit if GameState.interior_exit != "" else TOWN_SCENE
		GameState.interior_exit = ""
		travel(back, room_id)


# ---------- room ----------

# Zoom out so the whole room fits, and lock the camera in place on the room's centre.
func _pin_camera() -> void:
	var cam := player.get_node("Camera2D") as Camera2D
	var z := floorf(minf(1152.0 / (W * 16.0), 648.0 / (H * 16.0)) * 0.97 * 10.0) / 10.0
	cam.zoom = Vector2(z, z)
	cam.position_smoothing_enabled = false
	var half := Vector2(1152.0, 648.0) / z / 2.0
	var centre := Vector2(W * 8.0, H * 8.0)
	cam.limit_left = floori(centre.x - half.x)
	cam.limit_right = ceili(centre.x + half.x)
	cam.limit_top = floori(centre.y - half.y)
	cam.limit_bottom = ceili(centre.y + half.y)


func _build_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var floors: Array = room.floor
	for y in H:
		for x in W:
			set_tile(x, y, floors[rng.randi() % floors.size()])
	for x in W:
		set_tile(x, 0, room.wall_top)
		set_tile(x, 1, room.wall)
		if x < DOORWAY.x or x >= DOORWAY.y:
			set_tile(x, H - 1, room.wall)
	for y in H:
		set_tile(0, y, room.wall)
		set_tile(W - 1, y, room.wall)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	world.add_child(body)
	var w := W * 16
	var h := H * 16
	for r in [
		Rect2(0, 0, w, 32), Rect2(0, 0, 16, h), Rect2(w - 16, 0, 16, h),
		Rect2(0, h - 16, DOORWAY.x * 16, 16), Rect2(DOORWAY.y * 16, h - 16, w - DOORWAY.y * 16, 16),
	]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = r.size
		shape.shape = box
		shape.position = r.get_center()
		body.add_child(shape)


# A prop made from a tile on one of the sheets, standing on `feet`.
func _prop(sheet: Texture2D, idx: int, feet: Vector2, block := true) -> Node2D:
	var n := Node2D.new()
	n.position = feet
	n.add_child(Tiles.sprite(sheet, idx, Vector2(-8, -15)))
	world.add_child(n)
	if block:
		add_blocker(n, Rect2(-6, -6, 12, 6))
	return n


func _sprite_at(texture: Texture2D, pos: Vector2, z := 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.position = pos
	s.z_index = z
	world.add_child(s)
	return s


func _build_counter() -> void:
	var counter := Node2D.new()
	counter.position = COUNTER_POS
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.counter(COUNTER_TILES)
	sprite.centered = false
	counter.add_child(sprite)
	world.add_child(counter)
	var size := Vector2(COUNTER_TILES * 16, 22)
	add_blocker(counter, Rect2(Vector2.ZERO, size))

	# The shopkeeper stands behind the counter (just above it, so the counter draws in front).
	var keeper := Node2D.new()
	keeper.set_script(NpcScript)
	keeper.npc_id = room.keeper_id
	keeper.display_name = room.keeper_name
	keeper.tile = room.keeper_tile
	keeper.position = Vector2(COUNTER_POS.x + size.x / 2.0, COUNTER_POS.y - 2)
	world.add_child(keeper)
	add_interactable(counter, 18.0, _talk_keeper, Rect2(COUNTER_POS, size))


func _talk_keeper() -> void:
	# A quest from the shopkeeper comes first, then the shop opens.
	var quest_id := Quests.active_for(room.keeper_id)
	if quest_id != "":
		var t := Quests.talk(room.keeper_id)
		var after: Callable = t.get("after", Callable())
		hud.say(room.keeper_name, t.lines, func():
			if after.is_valid():
				var msg: String = after.call()
				if msg != "":
					hud.toast(msg)
			_open_room_shop())
	else:
		hud.say(room.keeper_name, [room.greeting], _open_room_shop)


func _open_room_shop() -> void:
	match room_id:
		"armory":
			open_outfitter()
		"royal_armory":
			open_menu("The Royal Armoury", _fill_royal_menu)
		"banquet":
			open_menu("The Banquet Hall", _fill_bakery)
		"smithy":
			open_menu("Tilda's Smithy", _fill_smithy)
		"study":
			open_menu("Merlo's Study", _fill_study)
		"bakery":
			open_menu("Finn's Bakery", _fill_bakery)
		_:
			open_menu("Gunnar's Butchery", _fill_butcher)


# ---------- armory ----------

func _decor(kind: String, pos: Vector2) -> Node2D:
	var d := Node2D.new()
	d.set_script(DecorScript)
	d.kind = kind
	d.position = pos
	world.add_child(d)
	return d


func _build_armory_props() -> void:
	# Slate flagstones over the whole room, with a red runner from the door up to the counter.
	_sprite_at(PixelArt.slate_floor(18, 11), Vector2(16, 32), -9)
	_sprite_at(PixelArt.slate_floor(2, 1), Vector2(DOORWAY.x * 16, (H - 1) * 16), -9)
	_sprite_at(PixelArt.rug(3, 6, Color("8b2f3c"), Color("e8c872")), Vector2(136, 126), -6)

	# Back wall: banners, a weapon rack over the shopkeeper, and flickering torches.
	for x in [32.0, 64.0, 240.0, 272.0]:
		_sprite_at(PixelArt.banner(), Vector2(x, 4), 2)
	_sprite_at(PixelArt.weapon_rack(), Vector2(138, 6), 2)
	for x in [104.0, 204.0, 20.0, 292.0]:
		_decor("torch", Vector2(x, 10))

	# A forge in the back-right corner, glowing, with an anvil beside it.
	var forge := Node2D.new()
	forge.position = Vector2(274, 88)
	var f := Sprite2D.new()
	f.texture = PixelArt.forge()
	f.centered = false
	f.position = Vector2(-18, -33)
	forge.add_child(f)
	var glow := PointLight2D.new()
	glow.texture = PixelArt.light()
	glow.color = Color(1.0, 0.55, 0.2)
	glow.texture_scale = 1.3
	glow.energy = 0.95
	glow.position = Vector2(0, -10)
	forge.add_child(glow)
	world.add_child(forge)
	add_blocker(forge, Rect2(-15, -24, 30, 24))
	_prop(DUNGEON, 74, Vector2(248, 100))

	# Suits of armor on stands, plus chests and barrels in the corners.
	for pos in [Vector2(36, 76), Vector2(40, 140), Vector2(284, 140), Vector2(60, 100)]:
		var stand := Node2D.new()
		stand.position = pos
		var s := Sprite2D.new()
		s.texture = PixelArt.armor_stand()
		s.centered = false
		s.position = Vector2(-11, -35)
		stand.add_child(s)
		world.add_child(stand)
		add_blocker(stand, Rect2(-8, -6, 16, 6))
	_prop(DUNGEON, 89, Vector2(2 * 16 + 8, 12 * 16))
	_prop(DUNGEON, 90, Vector2(17 * 16 + 8, 12 * 16))
	_prop(DUNGEON, 73, Vector2(3 * 16 + 12, 12 * 16))


# ---------- smithy ----------

func _glow(parent: Node2D, pos: Vector2, color: Color, scale_f: float, energy: float) -> void:
	var l := PointLight2D.new()
	l.texture = PixelArt.light()
	l.color = color
	l.texture_scale = scale_f
	l.energy = energy
	l.position = pos
	parent.add_child(l)


func _build_smithy_props() -> void:
	var floor_sprite := _sprite_at(PixelArt.slate_floor(18, 11), Vector2(16, 32), -9)
	floor_sprite.modulate = Color(0.82, 0.76, 0.76)
	_sprite_at(PixelArt.slate_floor(2, 1), Vector2(DOORWAY.x * 16, (H - 1) * 16), -9).modulate = Color(0.82, 0.76, 0.76)
	_sprite_at(PixelArt.rug(3, 6, Color("5a3b1e"), Color("b07a3c")), Vector2(136, 126), -6)
	for x in [24.0, 138.0, 252.0]:
		_sprite_at(PixelArt.weapon_rack(), Vector2(x, 6), 2)
	for x in [100.0, 204.0, 14.0, 298.0]:
		_decor("torch", Vector2(x, 10))

	# Big forge in the back-right corner, with sparks floating up from it.
	var forge := Node2D.new()
	forge.position = Vector2(272, 92)
	var f := Sprite2D.new()
	f.texture = PixelArt.forge()
	f.centered = false
	f.position = Vector2(-18, -33)
	forge.add_child(f)
	_glow(forge, Vector2(0, -10), Color(1.0, 0.5, 0.18), 1.5, 1.0)
	var sparks := CPUParticles2D.new()
	sparks.position = Vector2(0, -22)
	sparks.amount = 14
	sparks.lifetime = 1.4
	sparks.direction = Vector2(0, -1)
	sparks.spread = 25.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 10.0
	sparks.initial_velocity_max = 26.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 1.6
	sparks.color = Color("ffb04a")
	sparks.z_index = 20
	forge.add_child(sparks)
	world.add_child(forge)
	add_blocker(forge, Rect2(-15, -24, 30, 24))

	# Anvils, a grindstone and barrels.
	_prop(DUNGEON, 74, Vector2(244, 104))
	_prop(DUNGEON, 74, Vector2(60, 100))
	var grind := Node2D.new()
	grind.position = Vector2(40, 140)
	var g := Sprite2D.new()
	g.texture = PixelArt.grindstone()
	g.centered = false
	g.position = Vector2(-12, -21)
	grind.add_child(g)
	world.add_child(grind)
	add_blocker(grind, Rect2(-10, -8, 20, 8))
	_prop(DUNGEON, 73, Vector2(2 * 16 + 8, 12 * 16))
	_prop(DUNGEON, 73, Vector2(3 * 16 + 12, 12 * 16))
	_prop(DUNGEON, 90, Vector2(17 * 16 + 8, 12 * 16))


func _fill_smithy(m: PanelContainer) -> void:
	m.add_label("Each weapon adds damage on top of your sharpening level (%d). Gold: %d" % [GameState.damage, GameState.gold], UiStyle.MUTED, 15)
	var ids: Array = ["training"] + Weapons.SHOP_ORDER
	for id in Weapons.WEAPONS:
		if Weapons.WEAPONS[id].get("unique", false) and id in GameState.weapons:
			ids.append(id)
	for id in ids:
		var w: Dictionary = Weapons.WEAPONS[id]
		var owned: bool = id in GameState.weapons
		var equipped: bool = GameState.weapon == id
		var fx := Weapons.effect_text(w.effect)
		var stats := "+%d dmg" % w.dmg + (", " + fx if fx != "" else "")
		var text: String
		if equipped:
			text = "[Equipped]  %s   (%s)" % [w.name, stats]
		elif owned:
			text = "%s   (%s)   click to equip" % [w.name, stats]
		else:
			text = "%s   (%s)   %d gold" % [w.name, stats, w.price]
		m.add_button(text, _weapon_pressed.bind(id), equipped or (not owned and GameState.gold < w.price))
	m.add_label("%s: %s" % [GameState.weapon_data().name, GameState.weapon_data().desc], UiStyle.CREAM, 15)
	m.add_button("Done", close_menu)


func _weapon_pressed(id: String) -> void:
	var err := GameState.buy_or_equip_weapon(id)
	if err != "":
		hud.toast(err)
	else:
		hud.toast("Equipped the %s!" % Weapons.WEAPONS[id].name)
	refresh_menu()


# ---------- wizard's study ----------

func _build_study_props() -> void:
	_sprite_at(PixelArt.plank_floor(18, 11), Vector2(16, 32), -9)
	_sprite_at(PixelArt.plank_floor(2, 1), Vector2(DOORWAY.x * 16, (H - 1) * 16), -9)
	_sprite_at(PixelArt.rug(6, 3, Color("2c3a8a"), Color("c0b8ff")), Vector2(7 * 16, 9 * 16), -6)
	_sprite_at(PixelArt.rug(3, 4, Color("2c3a8a"), Color("c0b8ff")), Vector2(136, 138), -6)
	# Bookshelves along the back wall and a pair of violet torches.
	var seed_value := 1
	for x in [22.0, 56.0, 232.0, 266.0]:
		var shelf := _sprite_at(PixelArt.bookshelf(seed_value), Vector2(x, -2), 2)
		shelf.z_index = 2
		seed_value += 1
	for x in [112.0, 196.0]:
		var t := _decor("torch", Vector2(x, 10))
		t.light_color = Color(0.7, 0.55, 1.0)
	# A bubbling cauldron and a glowing crystal ball.
	var cauldron := Node2D.new()
	cauldron.position = Vector2(266, 104)
	var c := Sprite2D.new()
	c.texture = PixelArt.cauldron()
	c.centered = false
	c.position = Vector2(-14, -27)
	cauldron.add_child(c)
	_glow(cauldron, Vector2(0, -12), Color(0.35, 1.0, 0.55), 1.0, 0.8)
	world.add_child(cauldron)
	add_blocker(cauldron, Rect2(-11, -10, 22, 10))
	var orb := Node2D.new()
	orb.position = Vector2(52, 108)
	var o := Sprite2D.new()
	o.texture = PixelArt.crystal_ball()
	o.centered = false
	o.position = Vector2(-10, -29)
	orb.add_child(o)
	_glow(orb, Vector2(0, -16), Color(0.5, 0.55, 1.0), 1.0, 0.9)
	world.add_child(orb)
	add_blocker(orb, Rect2(-7, -8, 14, 8))
	_prop(DUNGEON, 113, Vector2(2 * 16 + 8, 12 * 16))
	_prop(DUNGEON, 114, Vector2(17 * 16 + 8, 12 * 16))
	_prop(DUNGEON, 66, Vector2(3 * 16 + 10, 12 * 16))
	# Floating magic dust.
	var dust := CPUParticles2D.new()
	dust.position = Vector2(160, 120)
	dust.amount = 26
	dust.lifetime = 6.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(140, 80)
	dust.direction = Vector2(0, -1)
	dust.spread = 180.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 8.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 1.8
	dust.color = Color(0.8, 0.75, 1.0, 0.8)
	dust.z_index = 5
	world.add_child(dust)


func _fill_study(m: PanelContainer) -> void:
	var gs := GameState
	m.add_label("Gold: %d      Mana: %d/%d      Mana potions: %d" % [gs.gold, gs.mp, gs.max_mp(), gs.mana_potions], UiStyle.MUTED, 16)
	m.add_label("Press F to cast fireball (%d mana). Mana recharges slowly; press M to drink a mana potion." % gs.FIREBALL_COST, UiStyle.CREAM, 15)
	if gs.spell < 1:
		m.add_button("Learn Fireball  (%d gold)    hurls a ball of fire that burns" % gs.FIREBALL_PRICE, _study_buy.bind("fireball"), gs.gold < gs.FIREBALL_PRICE)
	elif gs.spell == 1:
		m.add_label("Fireball learned!", UiStyle.BORDER, 17)
		m.add_button("Fireball II  (%d gold)    throws three fireballs at once" % gs.FIREBALL2_PRICE, _study_buy.bind("fireball2"), gs.gold < gs.FIREBALL2_PRICE)
	else:
		m.add_label("Fireball II mastered! Three fireballs per cast.", UiStyle.BORDER, 17)
	m.add_button("Mana Crystal  (%d gold)    +3 max mana  [%d/%d]" % [gs.CRYSTAL_PRICE, gs.mp_bonus / 3, gs.MAX_CRYSTALS], _study_buy.bind("crystal"), gs.mp_bonus >= gs.MAX_CRYSTALS * 3 or gs.gold < gs.CRYSTAL_PRICE)
	m.add_button("Mana Potion  (%d gold)    restores %d mana" % [gs.MANA_POTION_PRICE, gs.MANA_POTION_HEAL], _study_buy.bind("potion"), gs.gold < gs.MANA_POTION_PRICE or gs.mana_potions >= gs.POTION_CAP)
	m.add_button("Done", close_menu)


func _study_buy(what: String) -> void:
	var ok := false
	match what:
		"fireball":
			ok = GameState.buy_fireball()
			if ok:
				hud.toast("You learned Fireball! Press F to cast it.")
		"fireball2":
			ok = GameState.buy_fireball2()
			if ok:
				hud.toast("Fireball II! Three fireballs per cast.")
		"crystal":
			ok = GameState.buy_crystal()
			if ok:
				hud.toast("Max mana is now %d." % GameState.max_mp())
		"potion":
			ok = GameState.buy_mana_potion()
			if ok:
				hud.toast("Bought a mana potion.")
	refresh_menu()


# ---------- shared helpers for rooms with people ----------

func _add_npc(id: String, display: String, tile: int, pos: Vector2, wander := 0.0, tint := Color.WHITE, block := true) -> Node2D:
	var npc := Node2D.new()
	npc.set_script(NpcScript)
	npc.npc_id = id
	npc.display_name = display
	npc.tile = tile
	npc.position = pos
	npc.wander_r = wander
	npc.tint = tint
	world.add_child(npc)
	if wander == 0.0 and block:
		add_blocker(npc, Rect2(-4, -6, 8, 6))
	room_npcs[id] = npc
	return npc


# Says the NPC's quest dialogue (or an idle line), then runs `then` if given.
func _say_then(npc: Node2D, then: Callable = Callable()) -> void:
	var t := Quests.talk(npc.npc_id)
	var after: Callable = t.get("after", Callable())
	hud.say(npc.display_name, t.lines, func():
		if after.is_valid():
			var msg: String = after.call()
			if msg != "":
				hud.toast(msg)
		if then.is_valid():
			then.call())


func _chat(npc: Node2D) -> void:
	_say_then(npc)


func _open_menu_at(title: String, fill: Callable, pos: Vector2) -> void:
	menu_home = pos
	open_menu(title, fill)


# Closing any menu puts it back at its usual spot and hides the mirror's preview.
func close_menu() -> void:
	super()
	outfit_backdrop.visible = false
	outfit_preview.visible = false


# ---------- bakery ----------

const BAKERY_ITEMS := [
	{"id": "roll", "name": "Bread Roll", "price": 4, "desc": "+2 HP", "hp": 2},
	{"id": "pie", "name": "Meat Pie", "price": 12, "desc": "+5 HP", "hp": 5},
	{"id": "cake", "name": "Honey Cake", "price": 20, "desc": "+3 HP and Swift for 20 seconds", "hp": 3, "swift": 20.0},
	{"id": "tart", "name": "Berry Tart", "price": 18, "desc": "+2 HP and +5 mana", "hp": 2, "mp": 5},
	{"id": "feast", "name": "Hearty Breakfast", "price": 45, "desc": "Heals you fully, plus Rage for 15 seconds", "full": true, "rage": 15.0},
]


func _build_bakery_props() -> void:
	_sprite_at(PixelArt.checker_floor(18, 11), Vector2(16, 32), -9)
	_sprite_at(PixelArt.checker_floor(2, 1), Vector2(DOORWAY.x * 16, (H - 1) * 16), -9)
	_sprite_at(PixelArt.rug(3, 5, Color("e8707f"), Color("fff0f4")), Vector2(136, 130), -6)
	# Brick ovens glowing at the back, with bread shelves between them.
	for x in [44.0, 276.0]:
		var oven := Node2D.new()
		oven.position = Vector2(x, 56)
		var o := Sprite2D.new()
		o.texture = PixelArt.oven()
		o.centered = false
		o.position = Vector2(-20, -39)
		oven.add_child(o)
		_glow(oven, Vector2(0, -10), Color(1.0, 0.55, 0.2), 1.3, 0.9)
		world.add_child(oven)
		add_blocker(oven, Rect2(-18, -22, 36, 22))
	# Finn's kitchen: use the left-hand oven to cook your own meals.
	add_interactable(world, 24.0, func(): open_cooking("Finn's Kitchen"), Rect2(24, 14, 40, 48))
	for x in [96.0, 184.0]:
		_sprite_at(PixelArt.bread_shelf(), Vector2(x, 2), 2)
	_sprite_at(PixelArt.pastry_case(2), Vector2(COUNTER_POS.x + 4, COUNTER_POS.y - 14), 1)
	_sprite_at(PixelArt.pastry_case(2), Vector2(COUNTER_POS.x + 92, COUNTER_POS.y - 14), 1)
	for x in [14.0, 306.0]:
		_decor("torch", Vector2(x, 10))
	# Café tables with a few regulars.
	var tables := [Vector2(56, 150), Vector2(264, 150), Vector2(56, 196), Vector2(264, 196)]
	for t in tables:
		var table := Node2D.new()
		table.position = t
		var s := Sprite2D.new()
		s.texture = PixelArt.cafe_table()
		s.centered = false
		s.position = Vector2(-20, -29)
		table.add_child(s)
		world.add_child(table)
		add_blocker(table, Rect2(-14, -12, 28, 12))
	for c in [["tess", "Tess", 99, Vector2(43, 148), Color(1.0, 0.85, 0.85)], ["bo", "Bo", 86, Vector2(277, 148), Color(0.9, 0.95, 1.1)], ["mina", "Mina", 112, Vector2(43, 194), Color(1.1, 1.0, 0.8)]]:
		var npc := _add_npc(c[0], c[1], c[2], c[3], 0.0, c[4], false)
		add_interactable(npc, 26.0, func(): _chat(npc))


func _fill_bakery(m: PanelContainer) -> void:
	var gs := GameState
	m.add_label("Eat in and feel the difference!   HP %d/%d    MP %d/%d    Gold %d" % [gs.hp, gs.max_hp, gs.mp, gs.max_mp(), gs.gold], UiStyle.MUTED, 16)
	for item in _meal_items():
		var useless: bool = gs.hp >= gs.max_hp and not item.has("swift") and not item.has("rage") and not (item.has("mp") and gs.mp < gs.max_mp())
		m.add_button("%s  (%d gold)    %s" % [item.name, item.price, item.desc], _eat_here.bind(item.id), gs.gold < item.price or useless)
	m.add_button("Done", close_menu)


func _eat_here(id: String) -> void:
	for item in _meal_items():
		if item.id != id:
			continue
		if GameState.gold < item.price:
			return
		GameState.gold -= item.price
		if item.get("full", false):
			GameState.hp = GameState.max_hp
		else:
			GameState.heal(item.get("hp", 0))
		if item.has("mp"):
			GameState.mp = mini(GameState.mp + int(item.mp), GameState.max_mp())
		if item.has("swift"):
			GameState.buff_swift = maxf(GameState.buff_swift, float(item.swift))
		if item.has("rage"):
			GameState.buff_rage = maxf(GameState.buff_rage, float(item.rage))
		hud.toast("Yum! The %s hits the spot. %s" % [item.name, item.desc], UiStyle.BORDER)
	refresh_menu()


# ---------- town hall ----------

const GIVER_PLACES := {
	"rosa": "Town Hall", "gus": "east road", "pip": "the plaza", "lila": "the plaza",
	"hank": "west road", "odo": "the pond", "dusty": "the gallery", "merlo": "his study", "finn": "the bakery", "captain": "outside the Town Hall",
}
const HALL_DESK := Vector2(176, 82)
const HALL_BANK := Vector2(326, 124)


func _wall_sprite(texture: Texture2D, pos: Vector2) -> Sprite2D:
	return _sprite_at(texture, pos, 2)


func _build_hall() -> void:
	_sprite_at(PixelArt.marble_floor(W - 2, H - 3), Vector2(16, 32), -9)
	_sprite_at(PixelArt.marble_floor(2, 1), Vector2(DOORWAY.x * 16, (H - 1) * 16), -9)
	_sprite_at(PixelArt.rug(4, 12, Color("a32a3c"), Color("e8c872")), Vector2(W * 8.0 - 32.0, (H - 1) * 16 - 192.0), -6)

	# The back wall: map, library shelves, banners, notice board, trophy case, torches.
	var map_pos := Vector2(24, -2)
	var shelf_pos := Vector2(92, -4)
	var board_pos := Vector2(300, -2)
	var trophy_pos := Vector2(372, -8)
	_wall_sprite(PixelArt.map_board(), map_pos)
	_wall_sprite(PixelArt.bookshelf(21), shelf_pos)
	_wall_sprite(PixelArt.bookshelf(22), shelf_pos + Vector2(33, 0))
	for x in [150.0, 282.0]:
		_wall_sprite(PixelArt.banner(), Vector2(x, 4))
	_wall_sprite(PixelArt.notice_board(), board_pos)
	_wall_sprite(PixelArt.trophy_case(), trophy_pos)
	for x in [14.0, 84.0, 206.0, 238.0, 362.0, 428.0]:
		_decor("torch", Vector2(x, 10))

	# Marble pillars and benches along the carpet.
	for p in [Vector2(112, 204), Vector2(336, 204), Vector2(112, 266), Vector2(336, 266)]:
		var pillar := Node2D.new()
		pillar.position = p
		var ps := Sprite2D.new()
		ps.texture = PixelArt.pillar()
		ps.centered = false
		ps.position = Vector2(-9, -45)
		pillar.add_child(ps)
		world.add_child(pillar)
		add_blocker(pillar, Rect2(-7, -8, 14, 8))
	for p in [Vector2(150, 236), Vector2(298, 236)]:
		var bench := _decor("bench", p)
		add_blocker(bench, Rect2(-12, -8, 24, 8))

	# The mayor's desk, with Rosa behind it.
	var desk := Node2D.new()
	desk.position = HALL_DESK
	var dsprite := Sprite2D.new()
	dsprite.texture = PixelArt.desk(6)
	dsprite.centered = false
	desk.add_child(dsprite)
	world.add_child(desk)
	add_blocker(desk, Rect2(0, 4, 96, 22))
	var rosa := _add_npc("rosa", "Mayor Rosa", 99, Vector2(224, 80), 0.0, Color.WHITE, false)
	add_interactable(desk, 14.0, func(): _chat(rosa), Rect2(HALL_DESK, Vector2(96, 28)))

	# The treasury counter.
	var bank := Node2D.new()
	bank.position = HALL_BANK
	var bsprite := Sprite2D.new()
	bsprite.texture = PixelArt.counter(5)
	bsprite.centered = false
	bank.add_child(bsprite)
	world.add_child(bank)
	add_blocker(bank, Rect2(0, 0, 80, 22))
	_sprite_at(PixelArt.coin_pile(), HALL_BANK + Vector2(8, -10), 1)
	_sprite_at(PixelArt.coin_pile(), HALL_BANK + Vector2(50, -10), 1)
	var bea := _add_npc("bea", "Clerk Bea", 100, HALL_BANK + Vector2(40, -2), 0.0, Color(0.85, 1.05, 1.1), false)
	add_interactable(bank, 14.0, func(): _say_then(bea, func(): open_menu("Mossbrook Treasury", _fill_bank)), Rect2(HALL_BANK, Vector2(80, 22)))

	# The mirror, and a training dummy to hit.
	var mirror := Node2D.new()
	mirror.position = Vector2(396, 262)
	var ms := Sprite2D.new()
	ms.texture = PixelArt.mirror()
	ms.centered = false
	ms.position = Vector2(-13, -43)
	mirror.add_child(ms)
	world.add_child(mirror)
	add_blocker(mirror, Rect2(-9, -8, 18, 8))
	add_interactable(mirror, 26.0, _open_mirror)
	var dummy := Node2D.new()
	dummy.set_script(DummyScript)
	dummy.position = Vector2(56, 262)
	dummy.area = self
	world.add_child(dummy)
	add_blocker(dummy, Rect2(-6, -8, 12, 8))

	# Stations on the back wall: all you do is walk up and press Space.
	add_interactable(world, 22.0, _open_map, Rect2(map_pos, Vector2(52, 36)))
	add_interactable(world, 22.0, _open_bestiary_direct, Rect2(shelf_pos, Vector2(65, 36)))
	add_interactable(world, 22.0, func(): open_menu("Quest Board", _fill_board), Rect2(board_pos, Vector2(52, 36)))
	add_interactable(world, 22.0, func(): _open_menu_at("Hall of Heroes", _fill_trophies, Vector2(316, 60)), Rect2(trophy_pos, Vector2(40, 44)))

	# The people of the town hall.
	var orin := _add_npc("orin", "Librarian Orin", 111, Vector2(112, 64), 0.0, Color(0.85, 0.95, 1.1))
	add_interactable(orin, 28.0, func(): _say_then(orin, _open_bestiary_direct))
	var tam := _add_npc("tam", "Scribe Tam", 88, Vector2(326, 60), 0.0, Color(1.05, 0.95, 0.8))
	add_interactable(tam, 28.0, func(): _chat(tam))
	var ned := _add_npc("ned", "Town Crier Ned", 86, Vector2(224, 210), 44.0, Color(1.15, 0.9, 0.8))
	add_interactable(ned, 28.0, _ned_news)
	for c in [
		["brix", "Councilman Brix", 98, Vector2(158, 132), 0.0, Color(0.9, 0.9, 1.15)],
		["oona", "Councilwoman Oona", 99, Vector2(290, 132), 0.0, Color(1.1, 1.0, 0.8)],
		["mel", "Mel the Tourist", 85, Vector2(350, 224), 28.0, Color(0.85, 1.1, 0.85)],
		["pru", "Granny Pru", 100, Vector2(84, 208), 22.0, Color(1.1, 0.9, 1.1)],
	]:
		var npc := _add_npc(c[0], c[1], c[2], c[3], c[4], c[5])
		add_interactable(npc, 28.0, func(): _chat(npc))


func _ned_news() -> void:
	var lines: Array = ["Hear ye, hear ye! It is Day %d in Mossbrook!" % GameState.day]
	if GameState.flags.get("boss_defeated", false):
		lines.append("The King Slime has been DEFEATED! Praise be to our hero, %s!" % GameState.player_name)
	else:
		lines.append("The King Slime still lurks at the bottom of the old cave. Be brave, be ready!")
	var tips := [
		"At night, monsters raid the farm and the town. Sleep in your own bed to be safe!",
		"The bank pays interest every morning. Save your gold, and it grows!",
		"Every monster you defeat is recorded in the library. Orin loves a good bestiary.",
		"The training dummy is free to hit, and it teaches a little every day.",
		"Hazel's clinic heals for a few coins. Gunnar's meat heals on the go.",
	]
	lines.append(tips[randi() % tips.size()])
	hud.say("Town Crier Ned", lines)


func _open_bestiary_direct() -> void:
	_open_menu_at("Mossbrook Library: Bestiary", _fill_bestiary, Vector2(316, 28))


func _open_map() -> void:
	open_menu("Map of Mossbrook", _fill_map)


func _fill_map(m: PanelContainer) -> void:
	m.add_label("You are in the Town Hall, at the north end of the plaza.", UiStyle.CREAM, 16)
	for line in [
		"Your farm: far west along the road. Crops, a pond, and your house.",
		"Fountain plaza: just south of here. Mara's market, the quest board, and Pip.",
		"Bakery (north-west), Armory and Smithy: the houses along the north road.",
		"Merlo's Study and Bram's Builders: north-east. Gunnar's Butchery: far east.",
		"Wren's Pet Yard: south-west. The pond and Old Odo: south-east.",
		"Dusty's Shooting Gallery: south of the plaza. Hazel's Clinic: by the hall door.",
		"The old cave: the very end of the east road. The King Slime sleeps in the chamber below floor 2.",
	]:
		m.add_label(line, UiStyle.MUTED, 15)
	m.add_button("Done", close_menu)


# ---------- quest board ----------

func _fill_board(m: PanelContainer) -> void:
	var active: Array[String] = []
	var open_jobs: Array[String] = []
	var done := 0
	for id in Quests.ORDER:
		var d: Dictionary = Quests.DEFS[id]
		var giver: String = d.giver
		var place: String = GIVER_PLACES.get(giver, "town")
		if Quests.state(id) == "done":
			done += 1
		elif Quests.state(id) == "active":
			if Quests.is_ready(id):
				active.append("%s  -  READY! Return to %s (%s)" % [d.title, giver.capitalize(), place])
			else:
				active.append("%s  -  %d/%d %s   (%s, %s)" % [d.title, Quests.progress(id), d.goal, d.unit, giver.capitalize(), place])
		elif Quests.is_available(id):
			open_jobs.append("%s  -  ask %s at %s" % [d.title, giver.capitalize(), place])
	m.add_label("YOUR JOBS", UiStyle.BORDER, 17)
	if active.is_empty():
		m.add_label("Nothing in progress. Pick a job below!", UiStyle.MUTED, 15)
	for line in active:
		m.add_label(line, UiStyle.CREAM, 15)
	m.add_label("JOBS WAITING FOR A HERO", UiStyle.BORDER, 17)
	if open_jobs.is_empty():
		m.add_label("All posted jobs are taken. Check back after more are unlocked.", UiStyle.MUTED, 15)
	for line in open_jobs:
		m.add_label(line, UiStyle.CREAM, 15)
	m.add_label("Completed jobs: %d of %d" % [done, Quests.ORDER.size()], UiStyle.MUTED, 15)
	m.add_button("Done", close_menu)


# ---------- treasury ----------

func _fill_bank(m: PanelContainer) -> void:
	var gs := GameState
	m.add_label("Savings: %d gold      In your pocket: %d gold" % [gs.bank, gs.gold], UiStyle.CREAM, 18)
	m.add_label("Your savings earn 5%% interest every morning (up to 30 gold a day). Last payout: %d gold." % gs.bank_interest, UiStyle.MUTED, 15)
	m.add_button("Deposit 50", _bank_move.bind(50, true), gs.gold < 1)
	m.add_button("Deposit 200", _bank_move.bind(200, true), gs.gold < 1)
	m.add_button("Deposit everything", _bank_move.bind(999999, true), gs.gold < 1)
	m.add_button("Withdraw 50", _bank_move.bind(50, false), gs.bank < 1)
	m.add_button("Withdraw everything", _bank_move.bind(999999, false), gs.bank < 1)
	m.add_button("Done", close_menu)


func _bank_move(amount: int, deposit: bool) -> void:
	var n := GameState.deposit(amount) if deposit else GameState.withdraw(amount)
	hud.toast(("Deposited %d gold." if deposit else "Withdrew %d gold.") % n)
	refresh_menu()


# ---------- mirror ----------

func _open_mirror() -> void:
	outfit_backdrop.visible = true
	outfit_preview.visible = true
	outfit_preview.queue_redraw()
	_open_menu_at("The Mirror", _fill_mirror, Vector2(130, 120))


func _fill_mirror(m: PanelContainer) -> void:
	m.add_label("Change how you look. Armor and hats still show on top.", UiStyle.CREAM, 16)
	m.add_button("Change skin tone  (%d of %d)" % [_index_of(SKIN, GameState.skin_color) + 1, SKIN.size()], _cycle_look.bind("skin"))
	m.add_button("Change hair colour  (%d of %d)" % [_index_of(HAIR, GameState.hair_color) + 1, HAIR.size()], _cycle_look.bind("hair"))
	m.add_button("Change outfit colour  (%d of %d)" % [_index_of(SHIRT, GameState.shirt_color) + 1, SHIRT.size()], _cycle_look.bind("shirt"))
	m.add_button("Done", close_menu)


func _index_of(palette: Array, color: Color) -> int:
	for k in palette.size():
		if Color(palette[k]).is_equal_approx(color):
			return k
	return 0


func _cycle_look(part: String) -> void:
	match part:
		"skin":
			GameState.skin_color = Color(SKIN[(_index_of(SKIN, GameState.skin_color) + 1) % SKIN.size()])
		"hair":
			GameState.hair_color = Color(HAIR[(_index_of(HAIR, GameState.hair_color) + 1) % HAIR.size()])
		"shirt":
			GameState.shirt_color = Color(SHIRT[(_index_of(SHIRT, GameState.shirt_color) + 1) % SHIRT.size()])
	GameState.equipment_changed.emit()
	outfit_preview.queue_redraw()
	player.get_node("Avatar").queue_redraw()
	refresh_menu()


# ---------- bestiary ----------

const BESTIARY_PAGE := 6
var bestiary_page := 0


func _fill_bestiary(m: PanelContainer) -> void:
	var kinds: Array = Enemy.KINDS.keys()
	var pages := ceili(kinds.size() / float(BESTIARY_PAGE))
	bestiary_page = clampi(bestiary_page, 0, pages - 1)
	var known := 0
	for kind in kinds:
		if int(GameState.kills.get(kind, 0)) > 0:
			known += 1
	m.add_label("Monsters you have defeated: %d of %d      (page %d of %d)" % [known, kinds.size(), bestiary_page + 1, pages], UiStyle.BORDER, 16)
	for k in range(bestiary_page * BESTIARY_PAGE, mini((bestiary_page + 1) * BESTIARY_PAGE, kinds.size())):
		var kind: String = kinds[k]
		var n := int(GameState.kills.get(kind, 0))
		var d: Dictionary = Enemy.KINDS[kind]
		var nm: String = Enemy.NAMES.get(kind, String(kind).capitalize())
		if n > 0:
			m.add_label("%s   (defeated %d,  %d HP)" % [nm, n, d.hp], UiStyle.CREAM, 15)
			m.add_label(Enemy.TIPS[kind], UiStyle.MUTED, 13)
		else:
			m.add_label("???   Defeat one to write it in the book.", UiStyle.MUTED, 15)
	if pages > 1:
		m.add_button("Next page" if bestiary_page < pages - 1 else "Back to page 1", _bestiary_turn)
	m.add_button("Done", close_menu)


func _bestiary_turn() -> void:
	bestiary_page = (bestiary_page + 1) % ceili(Enemy.KINDS.size() / float(BESTIARY_PAGE))
	refresh_menu()


# ---------- hall of heroes ----------

func _fill_trophies(m: PanelContainer) -> void:
	var gs := GameState
	var species := Fish.all_species().size()
	var found := 0
	for s in Fish.all_species():
		if gs.fish_log.has(s):
			found += 1
	var done := 0
	for id in Quests.ORDER:
		if Quests.state(id) == "done":
			done += 1
	m.add_label("%s, level %d.   Gold earned shows in your pockets, glory shows here." % [gs.player_name, gs.level], UiStyle.CREAM, 15)
	var goals := [
		[gs.flags.get("boss_defeated", false), "Defeated the King Slime"],
		[gs.flags.get("royal_chest", false), "Claimed the King's treasure"],
		[found >= species, "Completed the fish book  (%d / %d species)" % [found, species]],
		[gs.gallery_best >= 30, "Scored 30 or more at the shooting gallery  (best %d)" % gs.gallery_best],
		[gs.level >= 10, "Reached level 10"],
		[gs.house_tier >= 3, "Built the Manor"],
		[gs.pet != "", "Befriended a pet"],
		[gs.weapons.size() >= 6, "Owns six or more weapons  (%d)" % gs.weapons.size()],
		[gs.spell >= 2, "Mastered Fireball II"],
		[done >= Quests.ORDER.size(), "Completed every job  (%d / %d)" % [done, Quests.ORDER.size()]],
	]
	var got := 0
	for g in goals:
		var ok: bool = g[0]
		if ok:
			got += 1
		m.add_label("%s  %s" % ["[x]" if ok else "[ ]", g[1]], UiStyle.BORDER if ok else UiStyle.MUTED, 15)
	m.add_label("%d of %d trophies earned" % [got, goals.size()], UiStyle.CREAM, 16)
	m.add_button("Done", close_menu)


# ---------- butcher ----------

func _build_butcher_props() -> void:
	for x in [28.0, 138.0, 248.0]:
		_sprite_at(PixelArt.meat_rack(), Vector2(x, 3), 1)
	var block := Node2D.new()
	block.position = Vector2(3 * 16 + 8, 9 * 16)
	var s := Sprite2D.new()
	s.texture = PixelArt.chopping_block()
	s.centered = false
	s.position = Vector2(-12, -20)
	block.add_child(s)
	world.add_child(block)
	add_blocker(block, Rect2(-8, -8, 16, 8))
	_prop(DUNGEON, 73, Vector2(17 * 16 + 8, 12 * 16))
	_prop(DUNGEON, 73, Vector2(16 * 16, 12 * 16 + 4))
	_prop(DUNGEON, 66, Vector2(2 * 16 + 8, 12 * 16))
	_prop(DUNGEON, 66, Vector2(3 * 16 + 10, 12 * 16 + 4))
	_sprite_at(PixelArt.rug(4, 2, Color("6b4a2f"), Color("c9a063")), Vector2(8 * 16, 9 * 16), -6)


func _fill_butcher(m: PanelContainer) -> void:
	var gs := GameState
	m.add_label("Press E any time to eat. Roast meat heals %d HP and prime steak heals %d HP." % [gs.MEAT_HEAL, gs.STEAK_HEAL], UiStyle.CREAM, 16)
	m.add_label("Gold: %d      Meat: %d      Steak: %d" % [gs.gold, gs.meat, gs.steak], UiStyle.MUTED, 16)
	m.add_button("Roast Meat  (%d gold)    heals %d HP" % [gs.MEAT_PRICE, gs.MEAT_HEAL], _buy_meat, gs.gold < gs.MEAT_PRICE or gs.meat >= gs.FOOD_CAP)
	m.add_button("Prime Steak  (%d gold)    heals %d HP" % [gs.STEAK_PRICE, gs.STEAK_HEAL], _buy_steak, gs.gold < gs.STEAK_PRICE or gs.steak >= gs.FOOD_CAP)
	m.add_button("Done", close_menu)


func _buy_meat() -> void:
	if GameState.buy_meat():
		hud.toast("Bought roast meat.")
	refresh_menu()


func _buy_steak() -> void:
	if GameState.buy_steak():
		hud.toast("Bought a prime steak.")
	refresh_menu()


# ---------- castle rooms ----------

const BANQUET_ITEMS := [
	{"id": "roast", "name": "Roast Boar", "price": 30, "desc": "+8 HP", "hp": 8},
	{"id": "stew", "name": "Royal Stew", "price": 40, "desc": "+6 HP and +8 mana", "hp": 6, "mp": 8},
	{"id": "tart", "name": "Honeyed Tart", "price": 35, "desc": "+4 HP and Swift for 30 seconds", "hp": 4, "swift": 30.0},
	{"id": "feast", "name": "The King's Feast", "price": 90, "desc": "Heals you fully, plus Rage for 25 seconds", "full": true, "rage": 25.0},
]


func _meal_items() -> Array:
	return BANQUET_ITEMS if room_id == "banquet" else BAKERY_ITEMS


func _stone_floor(tint: Color) -> void:
	var f := _sprite_at(PixelArt.slate_floor(W - 2, H - 3), Vector2(16, 32), -9)
	f.modulate = tint
	_sprite_at(PixelArt.slate_floor(2, 1), Vector2(DOORWAY.x * 16, (H - 1) * 16), -9).modulate = tint


func _torches(xs: Array) -> void:
	for x in xs:
		_decor("torch", Vector2(x, 10))


func _build_throne() -> void:
	_stone_floor(Color(1.0, 0.95, 0.92))
	var cx := W * 8.0
	# A long red carpet from the door to the steps.
	_sprite_at(PixelArt.rug(4, H - 5, Color("8b1f30"), Color("e8c872")), Vector2(cx - 32, 5 * 16), -6)
	for x in [40.0, 88.0, W * 16.0 - 88.0, W * 16.0 - 40.0]:
		_sprite_at(PixelArt.banner(), Vector2(x - 8, 4), 2)
	_torches([20.0, 64.0, W * 16.0 - 64.0, W * 16.0 - 20.0, cx - 70, cx + 70])
	_sprite_at(RegionArt.steps(8), Vector2(cx - 64, 58), -5)
	var throne := Node2D.new()
	throne.position = Vector2(cx, 80)
	var t := Sprite2D.new()
	t.texture = RegionArt.throne()
	t.centered = false
	t.position = Vector2(-18, -52)
	throne.add_child(t)
	world.add_child(throne)
	add_blocker(throne, Rect2(-14, -14, 28, 14))
	# Pillars down both sides.
	for y in [112.0, 160.0, 208.0]:
		for x in [56.0, W * 16.0 - 56.0]:
			_prop(DUNGEON, 74, Vector2(x, y))
	# The King, with two guards and a counsellor.
	var king := add_npc("aldric", "King Aldric", 99, Vector2(cx, 98), 0.0, Color(1.3, 1.1, 0.6), false)
	add_interactable(king, 30.0, func(): _talk_npc("aldric", "King Aldric", ["Welcome to Highgarden, traveller. Speak, and the Crown will listen."]))
	add_chatter("guard1", "Royal Guard", 96, Vector2(cx - 56, 106), 0.0, Color(1.2, 0.8, 0.8))
	add_chatter("guard2", "Royal Guard", 97, Vector2(cx + 56, 106), 0.0, Color(1.2, 0.8, 0.8))
	add_chatter("counsellor", "Counsellor Edda", 100, Vector2(cx + 96, 150), 0.0, Color(0.8, 0.9, 1.2))


func _build_banquet() -> void:
	var f := _sprite_at(PixelArt.plank_floor(W - 2, H - 3), Vector2(16, 32), -9)
	f.modulate = Color(1.0, 0.92, 0.84)
	_sprite_at(PixelArt.plank_floor(2, 1), Vector2(DOORWAY.x * 16, (H - 1) * 16), -9)
	_sprite_at(PixelArt.rug(5, 8, Color("8b1f30"), Color("e8c872")), Vector2(W * 8.0 - 40, 8 * 16), -6)
	for x in [40.0, 120.0, W * 16.0 - 120.0, W * 16.0 - 40.0]:
		_sprite_at(PixelArt.banner(), Vector2(x - 8, 4), 2)
	_torches([20.0, 80.0, W * 16.0 - 80.0, W * 16.0 - 20.0])
	for pos in [Vector2(40, 8 * 16), Vector2(W * 16.0 - 40 - 128, 8 * 16)]:
		var table := _sprite_at(RegionArt.long_table(8), pos, 0)
		add_blocker(table, Rect2(0, 8, 128, 22))
	# Diners at the tables.
	add_chatter("lord_a", "Lord Pemberton", 86, Vector2(40 + 20, 7 * 16 + 4), 0.0, Color(1.0, 0.85, 1.2))
	add_chatter("lady_a", "Lady Cecile", 99, Vector2(W * 16.0 - 40 - 100, 7 * 16 + 4), 0.0, Color(0.9, 0.8, 1.2))
	add_chatter("jester_b", "Jester Jingles", 84, Vector2(W * 8.0, 12 * 16), 30.0, Color(1.3, 0.8, 1.1))


func _build_royal_armory() -> void:
	_stone_floor(Color(0.9, 0.9, 1.05))
	_sprite_at(PixelArt.rug(3, 6, Color("2c3a8a"), Color("e8c872")), Vector2(136, 126), -6)
	for x in [32.0, 64.0, 240.0, 272.0]:
		_sprite_at(PixelArt.banner(), Vector2(x, 4), 2)
	_sprite_at(PixelArt.weapon_rack(), Vector2(138, 6), 2)
	_torches([104.0, 204.0, 20.0, 292.0])
	for pos in [Vector2(36, 76), Vector2(40, 140), Vector2(284, 76), Vector2(284, 140), Vector2(60, 100), Vector2(260, 100)]:
		var stand := Node2D.new()
		stand.position = pos
		var s := Sprite2D.new()
		s.texture = PixelArt.armor_stand()
		s.centered = false
		s.position = Vector2(-11, -35)
		stand.add_child(s)
		world.add_child(stand)
		add_blocker(stand, Rect2(-8, -6, 16, 6))


func _fill_royal_menu(m: PanelContainer) -> void:
	m.add_label("Royal arms. A sharper blade than any sold in town.   Gold: %d" % GameState.gold, UiStyle.MUTED, 15)
	for id in Weapons.ROYAL_ORDER:
		var w: Dictionary = Weapons.WEAPONS[id]
		var owned: bool = id in GameState.weapons
		var equipped: bool = GameState.weapon == id
		var stats := "+%d dmg, reach +%d" % [w.dmg, int(w.reach)]
		var text: String
		if equipped:
			text = "[Equipped]  %s   (%s)" % [w.name, stats]
		elif owned:
			text = "%s   (%s)   click to equip" % [w.name, stats]
		else:
			text = "%s   (%s)   %d gold" % [w.name, stats, w.price]
		m.add_button(text, _weapon_pressed.bind(id), equipped or (not owned and GameState.gold < w.price))
	m.add_button("Browse armour and helms...", func():
		close_menu()
		open_outfitter("royal"))
	m.add_button("Done", close_menu)


# Talk to someone in the room: their quest first, otherwise a greeting.
func _talk_npc(id: String, display: String, greeting: Array) -> void:
	if Quests.active_for(id) != "":
		var t := Quests.talk(id)
		var after: Callable = t.get("after", Callable())
		hud.say(display, t.lines, func():
			if after.is_valid():
				var msg: String = after.call()
				if msg != "":
					hud.toast(msg))
	else:
		hud.say(display, greeting)
