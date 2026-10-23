extends "res://area.gd"
# The inside of a shop. Walk in through a door in town; the room loads as its own small map.
# Walk back out through the doorway at the bottom to return to the street.

const NpcScript := preload("res://npc.gd")
const PixelArt := preload("res://pixel_art.gd")
const DecorScript := preload("res://decor.gd")

const W := 20
const H := 14
const COUNTER_TILES := 8
const COUNTER_POS := Vector2(96, 96) # top-left, in px
const DOORWAY := Vector2i(9, 11) # tile columns of the gap in the bottom wall

# floor tiles are picked at random from the list; walls use the dungeon sheet's brick.
const ROOMS := {
	"armory": {
		"title": "Brann's Armory", "floor": [0, 0, 0, 0, 0, 0, 0, 1], "wall": 57, "wall_top": 40, "tint": Color(0.68, 0.66, 0.8),
		"keeper_name": "Armorer Brann", "keeper_tile": 87,
		"greeting": "Welcome to my armory! Hats for style, armor for survival. Take a look!",
	},
	"butcher": {
		"title": "Gunnar's Butchery", "floor": [53, 53, 53, 53, 53, 49], "wall": 57, "wall_top": 40, "tint": Color(1.0, 0.95, 0.88),
		"keeper_name": "Butcher Gunnar", "keeper_tile": 98,
		"greeting": "Fresh meat, cut this morning! Nothing heals you like a good steak.",
	},
}

var room_id := "armory"
var room: Dictionary


func _ready() -> void:
	map_w = W
	map_h = H
	room_id = GameState.interior if GameState.interior in ROOMS else "armory"
	room = ROOMS[room_id]
	begin(DUNGEON)
	use_daylight = false
	canvas_mod.color = room.tint
	_build_ground()
	_build_walls()
	if room_id == "armory":
		_build_armory_props()
	else:
		_build_butcher_props()
	_build_counter()

	GameState.next_spawn = ""
	spawn_player(Vector2(160, H * 16 - 26))
	_pin_camera()
	raids = false
	finish("Space: talk to the shopkeeper   |   Walk out the bottom door to leave")
	hud.toast(room.title)


func _area_process(_delta: float) -> void:
	if not traveling and player.global_position.y > H * 16 - 10:
		GameState.interior = ""
		travel(TOWN_SCENE, room_id)


# ---------- room ----------

# Zoom out so the whole room fits, and lock the camera in place on the room's centre.
func _pin_camera() -> void:
	var cam := player.get_node("Camera2D") as Camera2D
	var z := 2.8
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
	keeper.npc_id = "keeper"
	keeper.display_name = room.keeper_name
	keeper.tile = room.keeper_tile
	keeper.position = Vector2(COUNTER_POS.x + size.x / 2.0, COUNTER_POS.y - 2)
	world.add_child(keeper)
	add_interactable(counter, 18.0, _talk_keeper, Rect2(COUNTER_POS, size))


func _talk_keeper() -> void:
	if room_id == "armory":
		hud.say(room.keeper_name, [room.greeting], open_outfitter)
	else:
		hud.say(room.keeper_name, [room.greeting], func(): open_menu("Gunnar's Butchery", _fill_butcher))


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
