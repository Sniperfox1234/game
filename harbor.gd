extends "res://region.gd"
# Port Saltmere: a stone quay and docks on the open sea, ships, a lighthouse, Salty's outfitters,
# and a rock arch on the western cliffs leading into Smugglers' Cove.

const GRASS := 0
const SAND := 3
const COBBLE := 2
const WATER := 9
const PLANKS := 11

const COVE_FEET := Vector2(150, 296)


func _ready() -> void:
	region_id = "harbor"
	map_w = 64
	map_h = 48
	roam_kinds = ["crab", "crab", "parrot", "pirate"]
	roam_max = 5
	begin(TOWN, true)
	_paint_terrain()
	_build_buildings()
	_build_docks()
	_build_cove()
	_build_people()
	add_carriage(Vector2(560, 300))
	build_water_blockers()
	add_sea_fishing(Rect2i(6, 31, 20, 14))
	add_sea_fishing(Rect2i(36, 31, 26, 14))
	add_sea_fishing(Rect2i(26, 40, 10, 6))
	fish_luck = 0.5

	spawn_player(region_spawn(Vector2(600, 320)))
	seed_roamers(4)
	finish()
	var quest_msg := Quests.event("visit_harbor")
	if quest_msg != "":
		hud.toast(quest_msg)
	hud.toast("Port Saltmere. The open sea is full of big fish, and pirates lurk in the cove.")


func music_for() -> String:
	return "mus_harbor"


func ambience_for() -> String:
	return "amb_waves"


func ambient_mode() -> String:
	return "leaves"


func fx_profile() -> Dictionary:
	return {"vignette": 0.28, "shafts": 0.08, "saturation": 1.15}


func _paint_terrain() -> void:
	paint_rect(Rect2i(0, 0, map_w, map_h), WATER)
	paint_rect(Rect2i(0, 0, map_w, 28), GRASS)
	paint_rect(Rect2i(0, 26, map_w, 4), SAND)
	# A stone quay along the shore and a cobbled square.
	paint_rect(Rect2i(14, 18, 44, 9), COBBLE)
	paint_rect(Rect2i(26, 8, 6, 10), COBBLE)
	# Western cliffs around the cove arch.
	paint_rect(Rect2i(2, 10, 16, 14), 5)
	# The eastern cape for the lighthouse.
	paint_rect(Rect2i(52, 24, 12, 10), SAND)
	paint_rect(Rect2i(56, 30, 8, 8), SAND)
	# Piers reaching into the sea.
	paint_rect(Rect2i(28, 28, 4, 12), PLANKS)
	paint_rect(Rect2i(44, 28, 4, 8), PLANKS)
	paint_rect(Rect2i(14, 28, 3, 6), PLANKS)
	# Beach of the little bay at the east.
	paint_rect(Rect2i(48, 28, 4, 3), SAND)


func _build_buildings() -> void:
	var red := [
		[0, 1, 2, 3], [16, 17, 18, 19], [32, 33, 34, 35], [48, 49, 50, 51]]
	# Use the same house art as Mossbrook, in a row along the quay.
	var town = load("res://town.gd")
	for x in [Vector2i(17, 10), Vector2i(36, 10), Vector2i(43, 10)]:
		build_house(x, town.GREY_HOUSE if x.x != 36 else town.RED_HOUSE)
	add_label("Harbourmaster", Vector2(17 * 16 + 32, 9 * 16))
	add_label("Fishmonger", Vector2(36 * 16 + 32, 9 * 16))
	for p in [Vector2(120, 700), Vector2(900, 90), Vector2(300, 80), Vector2(760, 90), Vector2(60, 450)]:
		add_small_tree(Vector2i(int(p.x / 16), int(p.y / 16)), false)
	add_decor("lamp", Vector2(15 * 16, 18 * 16 + 4))
	add_decor("lamp", Vector2(57 * 16, 18 * 16 + 4))
	add_decor("lamp", Vector2(24 * 16, 27 * 16))
	add_decor("lamp", Vector2(51 * 16, 27 * 16))


func _build_docks() -> void:
	add_prop(RegionArt.ship(), Vector2(380, 640), Rect2(), Vector2(0, 0))
	add_prop(RegionArt.ship(), Vector2(820, 600), Rect2(), Vector2(0, 0))
	add_prop(RegionArt.rowboat(), Vector2(488, 540), Rect2(), Vector2(0, 0))
	add_prop(RegionArt.rowboat(), Vector2(210, 500), Rect2(), Vector2(0, 0))
	for p in [Vector2(250, 440), Vector2(430, 410), Vector2(690, 410), Vector2(760, 440), Vector2(340, 410)]:
		add_prop(RegionArt.crates(), p, Rect2(-14, -12, 28, 12), Vector2(32, 8))
	add_prop(RegionArt.lighthouse(), Vector2(900, 440), Rect2(-16, -14, 32, 14), Vector2(60, 10))
	add_label("Saltmere Light", Vector2(900, 290), Color("ffd98a"))
	add_label("Port Saltmere", Vector2(480, 8 * 16), Color("ffd98a"))
	add_sign(Vector2(500, 430), [
		"Port Saltmere. Fish off the piers: the open sea's catches are bigger and rarer than any pond.",
		"Smugglers' Cove lies in the western cliffs. Captain Blackjaw and his crew hold it. Level 10 or higher is wise.",
	])


func _build_cove() -> void:
	add_prop(RegionArt.cave_arch(Color("6e7a8c")), COVE_FEET, Rect2(), Vector2(0, 0))
	add_block_rect(Rect2(COVE_FEET.x - 36, COVE_FEET.y - 50, 20, 52))
	add_block_rect(Rect2(COVE_FEET.x + 16, COVE_FEET.y - 50, 20, 52))
	add_block_rect(Rect2(COVE_FEET.x - 36, COVE_FEET.y - 56, 72, 30))
	entrances["cove"] = COVE_FEET + Vector2(0, -6)
	add_label("Smugglers' Cove", COVE_FEET + Vector2(0, -64), Color("ff9a8a"))


func _build_people() -> void:
	# Salty's outfitters stall on the quay.
	var stall := Vector2(620, 400)
	add_prop(RegionArt.tent(Color("3a6aa8"), Color("f4f4f4")), stall, Rect2(-34, -20, 68, 20), Vector2(70, 12))
	add_label("Salty's Outfitters", stall + Vector2(0, -62), Color("9fd8ff"))
	var salty := add_npc("salty", "Salty the Outfitter", 87, stall + Vector2(0, 14), 0.0, Color(0.8, 0.95, 1.2))
	add_interactable(salty, 30.0, func(): talk_person(salty, "salty", "Salty the Outfitter",
		["Ahoy! Coats for the cold wind and harpoons for the big ones. Take a look!"],
		func(): open_trader("Salty's Outfitters", "harbor", Weapons.HARBOR_ORDER)))
	var finn := add_npc("marta", "Fishmonger Marta", 99, Vector2(36 * 16 + 32, 14 * 16), 0.0, Color(1.1, 0.95, 0.9))
	add_interactable(finn, 28.0, func(): talk_person(finn, "marta", "Fishmonger Marta",
		["Fish bite better out at sea, love. Cast from the end of a pier and watch for the big ones!",
		"A legendary catch? They say the deep water holds more than any pond. Keep trying."]))
	var hm := add_npc("harbourmaster", "Harbourmaster Brine", 86, Vector2(17 * 16 + 32, 14 * 16), 0.0, Color(0.9, 0.95, 1.2))
	add_interactable(hm, 28.0, func(): talk_person(hm, "harbourmaster", "Harbourmaster Brine",
		["Blackjaw's crew hit our docks every week. The cove in the western cliffs is their den.",
		"Cannoneers fire in threes, so keep sidestepping. And Blackjaw himself charges like a bull!"]))
	add_chatter("sailor1", "Old Sailor", 112, Vector2(300, 470), 24.0, Color(0.9, 0.95, 1.1))
	add_chatter("sailor2", "Deckhand Pip", 88, Vector2(720, 460), 24.0, Color(1.1, 0.9, 0.9))
