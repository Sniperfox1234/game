extends "res://region.gd"
# Highgarden Castle: a safe royal court with a moat and drawbridge, a walled courtyard, and a keep
# with three doors (banquet hall, throne room, royal armoury).

const COURTYARD := 12 # terrain: courtyard stone
const WATER := 9
const PLANKS := 11

var keep_pos := Vector2(512, 280)


func _ready() -> void:
	region_id = "castle"
	map_w = 64
	map_h = 48
	begin(TOWN, true)
	_paint_terrain()
	build_forest(Rect2i(30, 46, 4, 2))
	_build_castle()
	_build_courtyard()
	_build_people()
	add_carriage(Vector2(480, 704))

	build_water_blockers()
	spawn_player(region_spawn(Vector2(512, 664)))
	finish()
	hud.toast("Highgarden Castle. The King holds court inside the keep.")


func music_for() -> String:
	return "mus_castle"


func ambience_for() -> String:
	return "amb_birds"


func ambient_mode() -> String:
	return "leaves"


# ---------- map ----------

func _paint_terrain() -> void:
	paint_rect(Rect2i(14, 9, 36, 24), COURTYARD)
	paint_rect(Rect2i(31, 36, 2, 12), COURTYARD) # the king's road south
	# Moat: a ring of water around the walls.
	paint_rect(Rect2i(12, 6, 2, 30), WATER)
	paint_rect(Rect2i(51, 6, 2, 30), WATER)
	paint_rect(Rect2i(12, 6, 41, 2), WATER)
	paint_rect(Rect2i(12, 33, 41, 3), WATER)
	paint_rect(Rect2i(31, 33, 2, 3), PLANKS) # the drawbridge
	# Gardens inside the walls: lawns on either side of the path.
	paint_rect(Rect2i(17, 20, 9, 8), 0)
	paint_rect(Rect2i(38, 20, 9, 8), 0)


func _build_castle() -> void:
	# Walls, towers and the gatehouse. Everything sits on the line the moat hugs.
	var south_left := Sprite2D.new()
	for x_tile in [Vector2(224, 480), Vector2(544, 480)]:
		var w := Sprite2D.new()
		w.texture = RegionArt.castle_wall(16)
		w.centered = false
		w.position = x_tile
		world.add_child(w)
	add_block_rect(Rect2(224, 488, 268, 44))
	add_block_rect(Rect2(532, 488, 268, 44))
	add_prop(RegionArt.castle_gatehouse(), Vector2(512, 536), Rect2())
	# The two gatehouse towers block; the arch between them is open.
	add_block_rect(Rect2(456, 480, 36, 56))
	add_block_rect(Rect2(532, 480, 36, 56))

	for pos in [Vector2(224, 540), Vector2(800, 540), Vector2(224, 196), Vector2(800, 196)]:
		add_prop(RegionArt.castle_tower(), pos, Rect2(-22, -26, 44, 26), Vector2(60, 14))

	for x in [214.0, 790.0]:
		var side := Sprite2D.new()
		side.texture = RegionArt.castle_wall_side(21)
		side.centered = false
		side.position = Vector2(x, 192)
		world.add_child(side)
		add_block_rect(Rect2(x, 192, 20, 330))
	# The north wall, to either side of the keep.
	for x in [254.0, 630.0]:
		var n := Sprite2D.new()
		n.texture = RegionArt.castle_wall(9)
		n.centered = false
		n.position = Vector2(x, 140)
		world.add_child(n)
		add_block_rect(Rect2(x, 150, 144, 46))

	# The keep, with its three doors.
	add_prop(RegionArt.castle_keep(), keep_pos, Rect2(-116, -110, 232, 108), Vector2(250, 20))
	doors["banquet"] = keep_pos + Vector2(48 - 116, 2)
	doors["throne"] = keep_pos + Vector2(0, 2)
	doors["royal_armory"] = keep_pos + Vector2(184 - 116, 2)
	add_label("Banquet Hall", doors["banquet"] + Vector2(0, -52))
	add_label("Throne Room", doors["throne"] + Vector2(0, -66))
	add_label("Royal Armoury", doors["royal_armory"] + Vector2(0, -52))
	add_label("Highgarden", Vector2(512, 614), Color("ffd98a"))


func _build_courtyard() -> void:
	# The fountain at the heart of the courtyard.
	var fountain := Node2D.new()
	fountain.set_script(load("res://fountain.gd"))
	fountain.position = Vector2(512, 392)
	world.add_child(fountain)
	add_blocker(fountain, Rect2(-25, -12, 50, 26))
	# Hedges and flower beds around the two lawns.
	for h in [Vector2(17 * 16, 19 * 16 + 4), Vector2(17 * 16, 28 * 16 + 4), Vector2(38 * 16, 19 * 16 + 4), Vector2(38 * 16, 28 * 16 + 4)]:
		var hedge := Sprite2D.new()
		hedge.texture = RegionArt.hedge(9)
		hedge.centered = false
		hedge.position = h
		world.add_child(hedge)
		add_block_rect(Rect2(h.x, h.y + 6, 144, 12))
	for pos in [Vector2(19 * 16, 23 * 16), Vector2(40 * 16, 23 * 16)]:
		add_decor("flowers", pos, Vector2(64, 16))
		add_decor("flowers", pos + Vector2(0, 32), Vector2(64, 16))
	# Lamps, benches, trees on the lawns.
	for pos in [Vector2(28 * 16, 15 * 16), Vector2(36 * 16, 15 * 16), Vector2(28 * 16, 29 * 16), Vector2(36 * 16, 29 * 16),
			Vector2(16 * 16, 12 * 16), Vector2(48 * 16, 12 * 16)]:
		var lamp := add_decor("lamp", pos)
		add_blocker(lamp, Rect2(-3, -6, 6, 6))
	for pos in [Vector2(22 * 16, 31 * 16 - 20), Vector2(41 * 16, 31 * 16 - 20)]:
		var bench := add_decor("bench", pos)
		add_blocker(bench, Rect2(-12, -8, 24, 8))
	for t in [Vector2i(19, 21), Vector2i(23, 25), Vector2i(42, 21), Vector2i(45, 25)]:
		add_small_tree(t, false)
	# The training yard: dummies and a fenced tilt yard.
	for pos in [Vector2(17 * 16, 14 * 16), Vector2(19 * 16, 14 * 16)]:
		var dummy := Node2D.new()
		dummy.set_script(load("res://dummy.gd"))
		dummy.position = pos
		dummy.area = self
		world.add_child(dummy)
		add_blocker(dummy, Rect2(-6, -8, 12, 8))
	add_label("Training Yard", Vector2(18 * 16, 14 * 16 - 38))
	var tilt := add_decor("fence", Vector2(40 * 16, 12 * 16), Vector2(140, 70))
	tilt.gap = Vector2(50, 90)
	add_label("The Lists", Vector2(40 * 16 + 70, 12 * 16 - 4))
	# Banners flanking the way to the keep.
	for x in [472.0, 536.0]:
		var b := Sprite2D.new()
		b.texture = load("res://pixel_art.gd").banner()
		b.centered = false
		b.position = Vector2(x, 300)
		world.add_child(b)
	add_sign(Vector2(480, 496), [
		"Welcome to Highgarden, seat of King Aldric.",
		"The keep has three doors: the Banquet Hall on the left, the Throne Room in the middle and the Royal Armoury on the right.",
	])


func _build_people() -> void:
	# Gate guards, and the court.
	add_chatter("guard1", "Gate Guard", 96, Vector2(480, 596), 0.0, Color(1.2, 0.8, 0.8))
	add_chatter("guard2", "Gate Guard", 97, Vector2(544, 596), 0.0, Color(1.2, 0.8, 0.8))
	add_chatter("wilm", "Herald Wilm", 88, Vector2(512, 452), 18.0, Color(1.2, 1.0, 0.7))
	add_chatter("cecile", "Lady Cecile", 99, Vector2(340, 372), 22.0, Color(0.9, 0.8, 1.2))
	add_chatter("pemberton", "Lord Pemberton", 86, Vector2(690, 372), 22.0, Color(1.0, 0.85, 1.2))
	add_chatter("ivo", "Gardener Ivo", 112, Vector2(300, 330), 24.0, Color(0.85, 1.15, 0.85))
	add_chatter("gareth", "Sir Gareth", 96, Vector2(300, 250), 0.0, Color(1.25, 1.15, 0.7))
	add_chatter("squire", "Squire Tam", 85, Vector2(340, 270), 28.0, Color(0.9, 1.0, 1.2))
	add_chatter("jingles", "Jester Jingles", 84, Vector2(612, 440), 36.0, Color(1.3, 0.8, 1.1))
	add_chatter("dob", "Stable Hand Dob", 88, Vector2(420, 670), 0.0, Color(1.0, 0.85, 0.65))
	var vera := add_npc("vera", "Court Alchemist Vera", 100, Vector2(700, 456), 0.0, Color(0.8, 0.95, 1.3))
	add_interactable(vera, 28.0, func(): say_then(vera, open_remedies))
