extends "res://region.gd"
# Sunscar Desert: dunes and ruins, an oasis, Zahra's tent, and the pyramid that leads down into the tomb.

const SAND := 3
const SCRUB := 10
const GRASS := 0
const WATER := 9

const PYRAMID_FEET := Vector2(512, 272)
const OASIS := Rect2i(10, 29, 13, 9)


func _ready() -> void:
	region_id = "desert"
	map_w = 64
	map_h = 48
	roam_kinds = ["scorpion", "scarab", "scarab", "sandwisp", "cursed"]
	roam_max = 6
	begin(TOWN, true)
	_paint_terrain()
	_build_scenery()
	_build_pyramid()
	_build_people()
	add_carriage(Vector2(170, 690))
	build_water_blockers()
	add_sea_fishing(OASIS)
	fish_luck = 0.2

	spawn_player(region_spawn(Vector2(210, 650)))
	seed_roamers(5)
	finish()
	var quest_msg := Quests.event("visit_desert")
	if quest_msg != "":
		hud.toast(quest_msg)
	hud.toast("Sunscar Desert. Scorpions and curses wander the dunes. Level 8 or higher is wise.")


func music_for() -> String:
	return "mus_desert"


func ambience_for() -> String:
	return "amb_wind"


func ambient_mode() -> String:
	return "sand"


func fx_profile() -> Dictionary:
	return {"vignette": 0.32, "shafts": 0.1, "saturation": 1.15, "contrast": 1.08}


func _paint_terrain() -> void:
	paint_rect(Rect2i(0, 0, map_w, map_h), SAND)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in 12:
		var w := rng.randi_range(3, 8)
		var h := rng.randi_range(2, 5)
		paint_rect(Rect2i(rng.randi_range(0, map_w - w), rng.randi_range(0, map_h - h), w, h), SCRUB)
	# The oasis: a grassy ring around a pond.
	paint_rect(Rect2i(OASIS.position.x - 2, OASIS.position.y - 2, OASIS.size.x + 4, OASIS.size.y + 4), GRASS)
	paint_rect(OASIS, WATER)
	# A beaten trail down from the pyramid and across to the carriage stop.
	paint_rect(Rect2i(30, 17, 4, 16), 1)
	paint_rect(Rect2i(30, 33, 4, 2), 1)
	paint_rect(Rect2i(10, 41, 12, 3), 1)


func _build_scenery() -> void:
	for p in [Vector2(176, 470), Vector2(238, 458), Vector2(358, 470), Vector2(176, 640), Vector2(340, 590), Vector2(940, 300), Vector2(880, 600)]:
		add_prop(RegionArt.palm(), p, Rect2(-5, -8, 10, 8), Vector2(40, 10))
	for p in [Vector2(90, 150), Vector2(150, 260), Vector2(620, 110), Vector2(740, 180), Vector2(930, 500), Vector2(700, 700), Vector2(400, 330), Vector2(560, 640), Vector2(960, 140)]:
		add_prop(RegionArt.cactus(), p, Rect2(-5, -6, 10, 6), Vector2(18, 6))
	# Ruins on the west side: a fallen colonnade.
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 8:
		var broken := i % 3 == 1
		add_prop(RegionArt.ruin_pillar(broken), Vector2(150 + i * 36, 170 + (i % 2) * 40), Rect2(-8, -8, 16, 8), Vector2(24, 8))
	add_prop(RegionArt.obelisk(), Vector2(260, 330), Rect2(-8, -8, 16, 8), Vector2(24, 8))
	add_prop(RegionArt.obelisk(), Vector2(790, 250), Rect2(-8, -8, 16, 8), Vector2(24, 8))
	add_label("Fallen Colonnade", Vector2(250, 120))
	add_label("Oasis", Vector2(OASIS.position.x * 16 + 104, OASIS.position.y * 16 - 40))
	add_sign(Vector2(470, 300), [
		"The Pyramid of the Pharaoh. Its tomb is full of scarabs, scorpions and the cursed dead.",
		"Poison and slowing curses abound. Level 8 or higher is wise. The Pharaoh sleeps in the deepest chamber.",
	])
	add_sign(Vector2(240, 650), ["Sunscar Desert. The carriage stop is here. Zahra's tent is to the east."])


func _build_pyramid() -> void:
	var n := add_prop(RegionArt.pyramid(), PYRAMID_FEET, Rect2(), Vector2(190, 18))
	# Solid everywhere except the doorway.
	add_block_rect(Rect2(PYRAMID_FEET.x - 76, PYRAMID_FEET.y - 112, 152, 84))
	add_block_rect(Rect2(PYRAMID_FEET.x - 90, PYRAMID_FEET.y - 30, 70, 30))
	add_block_rect(Rect2(PYRAMID_FEET.x + 20, PYRAMID_FEET.y - 30, 70, 30))
	entrances["tomb"] = PYRAMID_FEET + Vector2(0, -6)
	add_label("Pharaoh's Tomb", PYRAMID_FEET + Vector2(0, -122), Color("ffd98a"))


func _build_people() -> void:
	# Zahra's tent.
	var tent_feet := Vector2(810, 440)
	add_prop(RegionArt.tent(Color("c8503a"), Color("f2e2b0")), tent_feet, Rect2(-34, -20, 68, 20), Vector2(70, 12))
	add_label("Zahra's Wares", tent_feet + Vector2(0, -62), Color("ffd98a"))
	var zahra := add_npc("zahra", "Zahra the Trader", 100, tent_feet + Vector2(0, 14), 0.0, Color(1.2, 0.9, 0.6))
	add_interactable(zahra, 30.0, func(): talk_person(zahra, "zahra", "Zahra the Trader",
		["Welcome, traveller! Cool cloth for the heat, and a blade that sings through the dunes."],
		func(): open_trader("Zahra's Desert Wares", "desert", Weapons.DESERT_ORDER)))
	var idris := add_npc("idris", "Nomad Idris", 112, Vector2(300, 600), 20.0, Color(0.95, 0.85, 0.6))
	add_interactable(idris, 28.0, func(): talk_person(idris, "idris", "Nomad Idris",
		["The old tomb has been closed for a thousand years. Something has stirred it awake.",
		"Scarabs swarm the lower halls. If you go, bring potions and keep moving."]))
	var pell := add_npc("pell", "Scholar Pell", 85, Vector2(450, 220), 18.0, Color(0.9, 0.95, 1.2))
	add_interactable(pell, 28.0, func(): talk_person(pell, "pell", "Scholar Pell",
		["These hieroglyphs describe a Pharaoh who bound his guards to the stone. Their curses slow whoever they strike.",
		"His shockwaves can be outrun. The spear volleys, less so. Dodge sideways!"]))
	add_chatter("camelboy", "Camel Boy Sef", 88, Vector2(620, 520), 30.0, Color(1.1, 0.95, 0.7))
