extends "res://region.gd"
# Mistmere Swamp: mud, boardwalks over dark water, dead trees and glowing mushrooms, a witch's hut,
# a graveyard, and a mossy arch that leads down into the Rotting Bog.

const MUD := 7
const SWAMP_GRASS := 8
const WATER := 9
const PLANKS := 11

const BOG_FEET := Vector2(860, 300)


func _ready() -> void:
	region_id = "swamp"
	map_w = 64
	map_h = 48
	roam_kinds = ["bogslime", "bogslime", "bogdog", "wisp", "zombie"]
	roam_max = 6
	begin(TOWN, true)
	_paint_terrain()
	_build_scenery()
	_build_bog_entrance()
	_build_people()
	add_carriage(Vector2(160, 690))
	build_water_blockers()
	add_sea_fishing(Rect2i(6, 30, 14, 8))
	add_sea_fishing(Rect2i(38, 34, 16, 8))
	fish_luck = 0.1

	spawn_player(region_spawn(Vector2(210, 650)))
	seed_roamers(5)
	finish()
	var quest_msg := Quests.event("visit_swamp")
	if quest_msg != "":
		hud.toast(quest_msg)
	hud.toast("Mistmere Swamp. Poison hangs in the air. Bring antidotes. Level 12 or higher is wise.")


func music_for() -> String:
	return "mus_swamp"


func ambience_for() -> String:
	return "amb_swamp"


func ambient_mode() -> String:
	return "spores"


func fx_profile() -> Dictionary:
	return {"vignette": 0.42, "shafts": 0.0, "saturation": 0.95, "contrast": 1.05, "blur": 1.4}


func _paint_terrain() -> void:
	paint_rect(Rect2i(0, 0, map_w, map_h), SWAMP_GRASS)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 26:
		var w := rng.randi_range(3, 9)
		var h := rng.randi_range(2, 6)
		paint_rect(Rect2i(rng.randi_range(0, map_w - w), rng.randi_range(0, map_h - h), w, h), MUD)
	# Dark pools.
	paint_rect(Rect2i(6, 30, 14, 8), WATER)
	paint_rect(Rect2i(38, 34, 16, 8), WATER)
	paint_rect(Rect2i(24, 8, 9, 6), WATER)
	paint_rect(Rect2i(44, 14, 8, 5), WATER)
	# Mud clearing around the witch's hut and the bog arch.
	paint_rect(Rect2i(14, 8, 12, 7), MUD)
	paint_rect(Rect2i(50, 14, 10, 8), MUD)
	# Boardwalk from the carriage stop north to the hut and east to the arch.
	paint_rect(Rect2i(10, 40, 4, 4), PLANKS)
	paint_rect(Rect2i(12, 14, 2, 26), PLANKS)
	paint_rect(Rect2i(12, 14, 14, 2), PLANKS)
	paint_rect(Rect2i(26, 28, 28, 2), PLANKS)
	paint_rect(Rect2i(52, 14, 2, 16), PLANKS)


func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 22:
		var p := Vector2(rng.randf_range(40, 980), rng.randf_range(60, 740))
		if _near_walk(p):
			continue
		if i % 3 == 0:
			add_prop(RegionArt.big_mushrooms(), p, Rect2(-8, -8, 16, 8), Vector2(30, 8))
		else:
			add_prop(RegionArt.dead_tree(), p, Rect2(-7, -8, 14, 8), Vector2(40, 10))
	for i in 18:
		var p := Vector2(rng.randf_range(40, 980), rng.randf_range(60, 740))
		if not _near_walk(p):
			add_prop(RegionArt.reeds(), p)
	# A little graveyard.
	for i in 6:
		add_prop(RegionArt.gravestone(), Vector2(400 + (i % 3) * 40, 640 + (i / 3) * 40), Rect2(-7, -6, 14, 6), Vector2(18, 6))
	add_label("Boneyard", Vector2(440, 596))
	add_sign(Vector2(240, 650), ["Mistmere Swamp. Poison bogs and worse. Stay on the boardwalks where you can."])
	add_sign(Vector2(820, 330), [
		"The Rotting Bog. Poison slimes, hounds, wisps and walking dead.",
		"Poison drains your health over time. Antidotes help. The Witch Morwen waits at the bottom. Level 12 or higher is wise.",
	])


# True if a scenery piece at p would sit on a walkway or a clearing we want to keep open.
func _near_walk(p: Vector2) -> bool:
	for r in [Rect2(160, 620, 120, 90), Rect2(180, 200, 36, 440), Rect2(180, 200, 240, 40), Rect2(400, 440, 460, 36),
			Rect2(820, 200, 40, 280), Rect2(720, 200, 220, 140), Rect2(200, 100, 220, 160)]:
		if r.has_point(p):
			return true
	var tx := int(p.x / 16)
	var ty := int(p.y / 16)
	return terrain_types[clampi(ty, 0, map_h - 1) * map_w + clampi(tx, 0, map_w - 1)] == WATER


func _build_bog_entrance() -> void:
	add_prop(RegionArt.cave_arch(Color("4f6a4a")), BOG_FEET, Rect2(), Vector2(0, 0))
	add_block_rect(Rect2(BOG_FEET.x - 36, BOG_FEET.y - 50, 20, 52))
	add_block_rect(Rect2(BOG_FEET.x + 16, BOG_FEET.y - 50, 20, 52))
	add_block_rect(Rect2(BOG_FEET.x - 36, BOG_FEET.y - 56, 72, 30))
	entrances["bog"] = BOG_FEET + Vector2(0, -6)
	add_label("The Rotting Bog", BOG_FEET + Vector2(0, -64), Color("9be86a"))


func _build_people() -> void:
	# Elda's hut: a healer of poisons.
	var hut := Vector2(260, 220)
	add_prop(RegionArt.witch_hut(), hut, Rect2(-40, -48, 80, 48), Vector2(100, 12))
	add_label("Elda's Hut", hut + Vector2(0, -96), Color("9be86a"))
	var elda := add_npc("elda", "Hermit Elda", 100, hut + Vector2(0, 22), 0.0, Color(0.8, 1.15, 0.8))
	add_interactable(elda, 30.0, func(): talk_person(elda, "elda", "Hermit Elda",
		["Hee hee, a visitor! The Witch Morwen poisoned this marsh long ago. I brew what cures it.",
		"Poison ticks away your health, but my antidotes wash it out. Her pools of green sludge bite hard, so never stand in them!"],
		open_remedies))
	var bram := add_npc("trapper", "Trapper Bram", 88, Vector2(180, 600), 20.0, Color(0.9, 1.0, 0.85))
	add_interactable(bram, 28.0, func(): talk_person(bram, "trapper", "Trapper Bram",
		["Never seen the bog so restless. Zombies shamble up from the bottom and wisps spit poison.",
		"If you get poisoned, drink an antidote from Elda before it eats your health."]))
	add_chatter("frogboy", "Little Fenn", 85, Vector2(560, 470), 26.0, Color(0.85, 1.15, 0.85))
