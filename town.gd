extends "res://area.gd"
# Mossbrook: a proper little town. Farm road in the west, a plaza with a fountain in the middle,
# the town hall to the north, and the old cave at the end of the east road.

const NpcScript := preload("res://npc.gd")
const CaveScript := preload("res://cave.gd")
const StallScript := preload("res://stall.gd")
const FountainScript := preload("res://fountain.gd")
const DecorScript := preload("res://decor.gd")
const Houses := preload("res://houses.gd")
const GalleryScript := preload("res://gallery.gd")
const PixelArt := preload("res://pixel_art.gd")

const GRASS := [0, 0, 0, 0, 0, 0, 0, 1, 1, 2]
const PATH_TILE := 40
const PLAZA_TILE := 43
const PLAZA := Rect2i(21, 13, 14, 10)
const FARM_GAP := Rect2i(0, 16, 1, 4)
const ROAD_ROWS := Vector2i(17, 19) # rows 17 and 18
const TALK_REACH := 28.0
const RED_HOUSE := [[52, 53, 53, 54], [64, 65, 65, 66], [76, 77, 77, 79], [88, 90, 91, 88]]
const GREY_HOUSE := [[48, 49, 49, 50], [60, 61, 61, 62], [76, 77, 77, 79], [88, 90, 91, 88]]
const HALL := [[48, 49, 49, 49, 49, 50], [60, 61, 61, 61, 61, 62], [76, 77, 77, 77, 77, 79], [88, 88, 90, 91, 88, 88]]

var cave_pos := Vector2.ZERO
var doors := {} # shop id -> door position
var npcs := {} # id -> npc node
var gallery: CanvasLayer


func _ready() -> void:
	map_w = 56
	map_h = 36
	begin(TOWN)
	_build_ground()
	build_forest(FARM_GAP)
	_build_buildings()
	_build_plaza()
	_build_scenery()
	_build_pet_yard()
	_build_gallery_booth()
	_build_cave()
	_build_npcs()
	add_pond(Rect2i(40, 25, 9, 6))

	var spawn := Vector2(28, 17 * 16 + 8)
	if GameState.next_spawn == "cave":
		spawn = cave_pos + Vector2(0, 14)
	elif GameState.next_spawn in doors:
		spawn = doors[GameState.next_spawn] + Vector2(0, 22)
	GameState.next_spawn = ""
	spawn_player(spawn)
	raids = true
	finish()
	gallery = GalleryScript.new()
	add_child(gallery)
	gallery.finished.connect(_on_gallery_finished)
	minigame = gallery
	if not GameState.flags.get("seen_town", false):
		GameState.flags["seen_town"] = true
		hud.toast("Welcome to Mossbrook! Talk to people with Space.")


func _area_process(_delta: float) -> void:
	if traveling:
		return
	var p := player.global_position
	if p.x < 10.0:
		travel(FARM_SCENE, "east")
	else:
		for id in doors:
			var d: Vector2 = doors[id]
			if absf(p.x - d.x) < 9.0 and p.y < d.y + 8.0 and p.y > d.y - 6.0:
				GameState.interior = id
				travel(INTERIOR_SCENE, "")
				return
	if absf(p.x - cave_pos.x) < 9.0 and p.y < cave_pos.y - 6.0 and p.y > cave_pos.y - 24.0:
		GameState.cave_floor = 1
		travel(CAVE_SCENE, "town")


# ---------- map ----------

func _path(x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			set_tile(x, y, PATH_TILE)


func _build_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for y in map_h:
		for x in map_w:
			set_tile(x, y, GRASS[rng.randi() % GRASS.size()])
	_path(0, 17, 55, 18)   # west-east road
	_path(27, 8, 28, 31)   # north-south road
	for y in range(PLAZA.position.y, PLAZA.end.y):
		for x in range(PLAZA.position.x, PLAZA.end.x):
			set_tile(x, y, PLAZA_TILE)
	# Paths from each front door down to the road.
	for col in [6, 12, 18, 36, 40, 46]:
		_path(col, 13, col, 16)


func _build_buildings() -> void:
	doors["bakery"] = build_house(Vector2i(4, 9), RED_HOUSE)
	doors["armory"] = build_house(Vector2i(10, 9), GREY_HOUSE)
	doors["smithy"] = build_house(Vector2i(16, 9), GREY_HOUSE)
	doors["study"] = build_house(Vector2i(34, 9), RED_HOUSE)
	build_house(Vector2i(38, 9), GREY_HOUSE)   # builder's workshop
	doors["butcher"] = build_house(Vector2i(44, 9), RED_HOUSE)
	doors["hall"] = build_house(Vector2i(25, 3), HALL)
	_label("Bakery", Vector2(4 * 16 + 32, 9 * 16 + 10))
	_label("Armory", Vector2(10 * 16 + 32, 9 * 16 + 10))
	_label("Smithy", Vector2(16 * 16 + 32, 9 * 16 + 10))
	_label("Merlo's Study", Vector2(34 * 16 + 32, 9 * 16 + 10))
	_label("Butcher", Vector2(44 * 16 + 32, 9 * 16 + 10))
	_label("Town Hall", Vector2(28 * 16, 3 * 16 + 4))
	_label("Bram's Builders", Vector2(38 * 16 + 32, 9 * 16 + 10))
	_label("Pet Yard", Vector2(10 * 16, 23 * 16 + 2))
	_label("Mossbrook Pond", Vector2(44 * 16 + 8, 25 * 16 - 6))


func _label(text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color("fff3c4"))
	l.add_theme_color_override("font_outline_color", Color("2e2233"))
	l.add_theme_constant_override("outline_size", 3)
	l.position = pos - Vector2(l.get_minimum_size().x / 2.0, 0)
	l.z_index = 30
	world.add_child(l)
	# Centre properly once the label knows its size.
	l.position.x = pos.x - ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x / 2.0 - 2.0


func _decor(kind: String, pos: Vector2, size := Vector2.ZERO) -> Node2D:
	var d := Node2D.new()
	d.set_script(DecorScript)
	d.kind = kind
	d.position = pos
	if size != Vector2.ZERO:
		d.w = size.x
		d.h = size.y
	world.add_child(d)
	return d


func _build_plaza() -> void:
	# The fountain: a circular basin in the middle of the plaza. Toss a coin for a wish.
	var fountain := Node2D.new()
	fountain.set_script(FountainScript)
	fountain.position = Vector2(28 * 16, 18 * 16)
	world.add_child(fountain)
	add_blocker(fountain, Rect2(-25, -12, 50, 26))
	add_interactable(fountain, 20.0, _wish, Rect2(fountain.position + Vector2(-25, -12), Vector2(50, 26)))

	# Mara's market stall, with Mara behind the counter.
	var stall := Node2D.new()
	stall.set_script(StallScript)
	stall.position = Vector2(24 * 16 + 8, 16 * 16)
	world.add_child(stall)
	add_blocker(stall, Rect2(-14, -12, 28, 12))
	var mara := _add_npc("mara", "Mara", 100, stall.position + Vector2(0, -5))
	mara.set_meta("no_blocker", true)
	add_interactable(stall, 34.0, _open_market)

	# The smithy's outdoor anvil, where Jun practises.
	var anvil := Node2D.new()
	anvil.position = Vector2(32 * 16, 16 * 16)
	anvil.add_child(Tiles.sprite(DUNGEON, 74, Vector2(-8, -15)))
	world.add_child(anvil)
	add_blocker(anvil, Rect2(-6, -8, 12, 8))

	for pos in [Vector2(24 * 16, 21 * 16), Vector2(32 * 16, 21 * 16), Vector2(28 * 16, 14 * 16 - 4)]:
		var bench := _decor("bench", pos)
		add_blocker(bench, Rect2(-12, -8, 24, 8))
	for pos in [Vector2(21 * 16, 13 * 16 + 8), Vector2(35 * 16 - 8, 13 * 16 + 8), Vector2(21 * 16, 22 * 16), Vector2(35 * 16 - 8, 22 * 16)]:
		var lamp := _decor("lamp", pos)
		add_blocker(lamp, Rect2(-3, -6, 6, 6))


func _build_scenery() -> void:
	# Lamps along the roads.
	for pos in [Vector2(16 * 16, 16 * 16 + 8), Vector2(8 * 16, 16 * 16 + 8), Vector2(40 * 16, 16 * 16 + 8), Vector2(47 * 16, 16 * 16 + 8),
			Vector2(26 * 16, 10 * 16), Vector2(30 * 16, 10 * 16), Vector2(26 * 16, 27 * 16), Vector2(30 * 16, 27 * 16)]:
		var lamp := _decor("lamp", pos)
		add_blocker(lamp, Rect2(-3, -6, 6, 6))
	# Flower beds by the hall door and around the plaza.
	for pos in [Vector2(22 * 16, 7 * 16 + 4), Vector2(31 * 16, 7 * 16 + 4), Vector2(22 * 16, 23 * 16), Vector2(32 * 16, 23 * 16),
			Vector2(13 * 16, 14 * 16), Vector2(7 * 16, 14 * 16)]:
		_decor("flowers", pos, Vector2(48, 16))
	# Quest board at the edge of the plaza.
	add_sign(Vector2(20 * 16 + 8, 16 * 16 + 4), _board_lines)
	add_sign(Vector2(51 * 16 + 8, 16 * 16 + 4), [
		"DANGER: Old cave ahead.",
		"Slimes, goblins and worse. Bring potions. Dash with Shift!",
	])
	for t in [Vector2i(3, 5), Vector2i(17, 6), Vector2i(21, 5), Vector2i(34, 5), Vector2i(36, 5), Vector2i(49, 5), Vector2i(3, 14),
			Vector2i(18, 25), Vector2i(21, 28), Vector2i(34, 28), Vector2i(38, 22), Vector2i(51, 22), Vector2i(52, 28), Vector2i(3, 33), Vector2i(24, 32)]:
		add_small_tree(t)
	for t in [Vector2i(15, 14), Vector2i(41, 14), Vector2i(36, 25), Vector2i(50, 14)]:
		var bush := Node2D.new()
		bush.position = Vector2(t.x * 16, (t.y + 1) * 16)
		bush.add_child(Tiles.sprite(TOWN, 5, Vector2(0, -16)))
		world.add_child(bush)
		add_blocker(bush, Rect2(2, -10, 12, 10))
	for t in [Vector2i(6, 20), Vector2i(19, 22), Vector2i(37, 20), Vector2i(32, 29), Vector2i(53, 21), Vector2i(15, 3)]:
		add_mushroom(t)


func _board_lines() -> Array:
	var text := Quests.tracker_text()
	return ["Mossbrook Quest Board", text if GameState.quests.size() > 0 else "No jobs taken yet. Talk to Rosa, Gus and Pip!"]


# Wren's pet yard: a fenced paddock in the south-west with adoptable critters inside.
func _build_pet_yard() -> void:
	var origin := Vector2(4 * 16, 24 * 16)
	var size := Vector2(12 * 16, 7 * 16)
	var fence := _decor("fence", origin, size)
	fence.gap = Vector2(size.x / 2.0 - 16.0, size.x / 2.0 + 16.0)
	# Fence collision: left, right, bottom, and the top on either side of the gate.
	add_blocker(world, Rect2(origin + Vector2(-2, -4), Vector2(4, size.y + 4)))
	add_blocker(world, Rect2(origin + Vector2(size.x - 2, -4), Vector2(4, size.y + 4)))
	add_blocker(world, Rect2(origin + Vector2(0, size.y - 3), Vector2(size.x, 4)))
	add_blocker(world, Rect2(origin + Vector2(0, -4), Vector2(fence.gap.x, 4)))
	add_blocker(world, Rect2(origin + Vector2(fence.gap.y, -4), Vector2(size.x - fence.gap.y, 4)))
	for c in [[120, Vector2(7 * 16, 28 * 16)], [124, Vector2(12 * 16, 27 * 16)], [121, Vector2(14 * 16, 29 * 16)]]:
		var critter := _decor("critter", c[1])
		critter.tile = c[0]


func _build_cave() -> void:
	var cave := Node2D.new()
	cave.set_script(CaveScript)
	cave.position = Vector2(53 * 16 + 8, 17 * 16)
	world.add_child(cave)
	add_blocker(cave, Rect2(-24, -30, 14, 30))
	add_blocker(cave, Rect2(10, -30, 14, 30))
	add_blocker(cave, Rect2(-10, -30, 20, 10))
	cave_pos = cave.position


# ---------- people ----------

const SPECIAL_NPCS := ["bram", "wren", "mara", "odo", "hazel", "penny", "lark", "dusty"]


func _build_npcs() -> void:
	_add_npc("captain", "Captain Vale", 97, Vector2(29 * 16, 9 * 16 + 4))
	_add_npc("pip", "Pip", 85, Vector2(23 * 16, 19 * 16), 44.0)
	_add_npc("gus", "Gus", 96, Vector2(50 * 16, 19 * 16))
	_add_npc("durin", "Durin", 87, Vector2(48 * 16, 16 * 16), 14.0)
	_add_npc("bram", "Bram the Builder", 86, Vector2(40 * 16 + 8, 14 * 16 + 4))
	_add_npc("odo", "Old Odo", 111, Vector2(40 * 16, 24 * 16 + 8))
	_add_npc("wren", "Wren", 112, Vector2(10 * 16, 25 * 16 + 4), 18.0)
	# Newer arrivals. Several are tinted so the same sprites look like different people.
	_add_npc("jun", "Jun the Apprentice", 88, Vector2(33 * 16, 16 * 16), 0.0, Color(1.0, 0.8, 0.65))
	_add_npc("moss", "Elder Moss", 111, Vector2(30 * 16 + 8, 20 * 16 + 4), 0.0, Color(0.8, 0.88, 1.15))
	_add_npc("penny", "Postmistress Penny", 99, Vector2(24 * 16, 11 * 16 + 4), 0.0, Color(1.1, 0.85, 1.0))
	_add_npc("hank", "Farmer Hank", 88, Vector2(14 * 16, 19 * 16), 18.0, Color(0.75, 1.0, 0.75))
	_add_npc("lila", "Lila", 85, Vector2(27 * 16, 21 * 16), 34.0, Color(1.1, 0.8, 0.8))
	_add_npc("brine", "Captain Brine", 98, Vector2(46 * 16, 24 * 16 + 4), 0.0, Color(0.7, 0.85, 1.15))
	_add_npc("rue", "Gardener Rue", 112, Vector2(23 * 16 + 8, 22 * 16 + 8), 14.0, Color(0.85, 1.1, 0.85))
	_add_npc("lark", "Lark the Bard", 84, Vector2(30 * 16, 15 * 16 + 4), 10.0, Color(1.15, 0.85, 1.1))
	_add_npc("hazel", "Healer Hazel", 100, Vector2(31 * 16 + 8, 12 * 16), 0.0, Color(0.85, 1.1, 1.1))
	add_interactable(npcs["bram"], TALK_REACH, _talk_bram)
	add_interactable(npcs["wren"], TALK_REACH, _talk_wren)
	add_interactable(npcs["odo"], TALK_REACH, _talk_odo)
	add_interactable(npcs["hazel"], TALK_REACH, _talk_hazel)
	add_interactable(npcs["penny"], TALK_REACH, _talk_penny)
	add_interactable(npcs["lark"], TALK_REACH, _talk_lark)


func _add_npc(id: String, display: String, tile: int, pos: Vector2, wander := 0.0, tint := Color.WHITE) -> Node2D:
	var npc := Node2D.new()
	npc.set_script(NpcScript)
	npc.npc_id = id
	npc.display_name = display
	npc.tile = tile
	npc.position = pos
	npc.wander_r = wander
	npc.tint = tint
	world.add_child(npc)
	if wander == 0.0 and not npc.has_meta("no_blocker"):
		add_blocker(npc, Rect2(-4, -6, 8, 6))
	npcs[id] = npc
	# Villagers with their own menus are wired up separately; everyone else just chats.
	if id not in SPECIAL_NPCS:
		add_interactable(npc, TALK_REACH, func(): _talk(npc))
	return npc


func _talk(npc: Node2D) -> void:
	var t := Quests.talk(npc.npc_id)
	var after: Callable = t.get("after", Callable())
	hud.say(npc.display_name, t.lines, func():
		if after.is_valid():
			var msg: String = after.call()
			if msg != "":
				hud.toast(msg))


func _open_market() -> void:
	hud.say("Mara", ["Fresh seeds, potions and sharp swords! I also buy crops, fish and mushrooms."], open_shop)


# ---------- fountain ----------

func _wish() -> void:
	if GameState.gold < 1:
		hud.toast("You have no coin to toss.")
		return
	hud.say("Fountain", ["You toss a coin into the fountain and make a wish..."], func():
		GameState.gold -= 1
		var r := randf()
		if r < 0.45:
			hud.toast("The water ripples, but nothing happens.")
		elif r < 0.65:
			GameState.gold += 4
			hud.toast("A shiny coin floats up. +3 gold!")
		elif r < 0.85:
			GameState.hp = GameState.max_hp
			hud.toast("A warm glow washes over you. Fully healed!")
		elif r < 0.95:
			GameState.fish += 1
			hud.toast("A fish leaps out of the fountain! +1 fish")
		else:
			GameState.potions = mini(GameState.potions + 1, GameState.POTION_CAP)
			hud.toast("A potion bobs to the surface!"))


# ---------- builder ----------

func _talk_bram() -> void:
	var t := Quests.talk("bram")
	hud.say("Bram the Builder", t.lines, func(): open_menu("Bram's Builders", _fill_builder))


func _fill_builder(m: PanelContainer) -> void:
	var tier := GameState.house_tier
	m.add_label("Your house: %s" % Houses.tier_data(tier).name, UiStyle.CREAM, 19)
	m.add_label("You have: %d wood, %d stone, %d gold" % [GameState.wood, GameState.stone, GameState.gold], UiStyle.MUTED, 16)
	if tier >= Houses.TIERS.size():
		m.add_label("Your house is a grand manor. There's nothing left to build!", UiStyle.BORDER, 18)
	else:
		var next: Dictionary = Houses.TIERS[tier]
		m.add_label("Next: %s" % next.name, UiStyle.BORDER, 19)
		m.add_label(next.perk, UiStyle.CREAM, 16)
		var needs: Array[String] = []
		if next.wood > 0:
			needs.append("%d wood" % next.wood)
		if next.stone > 0:
			needs.append("%d stone" % next.stone)
		if next.gold > 0:
			needs.append("%d gold" % next.gold)
		m.add_label("Needs: " + ", ".join(needs), UiStyle.MUTED, 16)
		m.add_button("Build the %s" % next.name, _do_build, not Houses.can_afford(next))
	m.add_label("Tip: chop small trees for wood, and mine the brown rocks in the cave for stone.", UiStyle.MUTED, 14)
	m.add_button("Done", close_menu)


func _do_build() -> void:
	if Houses.upgrade():
		hud.toast("Bram: All done! Go and have a look at your farm!")
	refresh_menu()


# ---------- pet shop ----------

func _talk_wren() -> void:
	var lines: Array = ["Welcome to the pet yard! I look after every critter in Mossbrook."]
	if GameState.level < GameState.PET_LEVEL:
		lines.append("Pets are for proven heroes. Come back when you're level %d!" % GameState.PET_LEVEL)
	elif GameState.pet == "":
		lines.append("You've earned a companion, hero! Pick whichever one speaks to you.")
	else:
		lines.append("How is %s doing? You can swap companions any time, for free." % PetScript.KINDS[GameState.pet].name)
	hud.say("Wren", lines, func(): open_menu("Wren's Pet Yard", _fill_pets))


func _fill_pets(m: PanelContainer) -> void:
	if GameState.level < GameState.PET_LEVEL:
		m.add_label("Pets are for heroes of level %d or higher. You are level %d. Keep fighting!" % [GameState.PET_LEVEL, GameState.level])
		m.add_button("Okay", close_menu)
		return
	m.add_label("Pets follow you, fight enemies for you, and get stronger as you level up. They can't be hurt!", UiStyle.CREAM, 16)
	var descs := {
		"dog": "Biscuit the Dog: runs in and bites",
		"bat": "Flit the Bat: fast, flighty, quick bites",
		"ghost": "Boo the Ghost: shoots spirit bolts from afar",
	}
	for kind in descs:
		var with_you: bool = GameState.pet == kind
		var price_text := "free swap" if GameState.pet != "" else "%d gold" % GameState.PET_PRICE
		var label: String = "[With you]  %s" % descs[kind] if with_you else "%s  (%s)" % [descs[kind], price_text]
		var cant_pay := GameState.pet == "" and GameState.gold < GameState.PET_PRICE
		m.add_button(label, _adopt.bind(kind), with_you or cant_pay)
	if GameState.pet != "":
		m.add_button("Send my pet home to rest", _adopt.bind(""))
	m.add_button("Done", close_menu)


func _adopt(kind: String) -> void:
	if GameState.pet == "" and kind != "":
		if GameState.gold < GameState.PET_PRICE:
			return
		GameState.gold -= GameState.PET_PRICE
	GameState.pet = kind
	spawn_pet()
	if kind != "":
		hud.toast("%s joins your adventure!" % PetScript.KINDS[kind].name)
	refresh_menu()


# ---------- shared dialogue helper ----------

# Says the NPC's quest dialogue (or an idle line), then runs `then`.
func _say_then(npc: Node2D, then: Callable) -> void:
	var t := Quests.talk(npc.npc_id)
	var after: Callable = t.get("after", Callable())
	hud.say(npc.display_name, t.lines, func():
		if after.is_valid():
			var msg: String = after.call()
			if msg != "":
				hud.toast(msg)
		then.call())


# ---------- Odo: tackle shop and fish book ----------

func _talk_odo() -> void:
	_say_then(npcs["odo"], func(): open_menu("Odo's Bait & Tackle", _fill_odo))


func _fill_odo(m: PanelContainer) -> void:
	var rod: Dictionary = Fish.RODS[GameState.rod]
	m.add_label("Your rod: %s. Better rods find rarer fish, and so does a quick hand on the bite." % rod.name, UiStyle.CREAM, 16)
	if GameState.rod < Fish.RODS.size() - 1:
		var next: Dictionary = Fish.RODS[GameState.rod + 1]
		m.add_button("Buy the %s  (%d gold)" % [next.name, next.price], _buy_rod, GameState.gold < next.price)
	else:
		m.add_label("You have the finest rod in Mossbrook!", UiStyle.BORDER, 16)
	var species := Fish.all_species()
	var found := 0
	for s in species:
		if GameState.fish_log.has(s):
			found += 1
	m.add_label("FISH BOOK   %d / %d species   (sell fish at any market stall)" % [found, species.size()], UiStyle.BORDER, 16)
	for r in Fish.RARITIES:
		var info: Dictionary = Fish.INFO[r]
		var parts: Array[String] = []
		for s in info.species:
			parts.append("%s %s" % ["[x]" if GameState.fish_log.has(s) else "[ ]", s])
		m.add_label("%s (%dg):  %s" % [info.name, info.price, "   ".join(parts)], info.color, 14)
	for r in GameState.book_rewards_ready():
		m.add_button("Claim the %s set reward: +%d gold" % [Fish.INFO[r].name, Fish.BOOK_REWARDS[r]], _claim_book.bind(r))
	m.add_button("Done", close_menu)


func _buy_rod() -> void:
	var next: Dictionary = Fish.RODS[GameState.rod + 1]
	if GameState.gold >= next.price:
		GameState.gold -= next.price
		GameState.rod += 1
		hud.toast("You bought the %s!" % next.name)
	refresh_menu()


func _claim_book(rarity: String) -> void:
	GameState.fish_claimed.append(rarity)
	GameState.gold += Fish.BOOK_REWARDS[rarity]
	hud.toast("Fish book reward: +%d gold!" % Fish.BOOK_REWARDS[rarity])
	refresh_menu()


# ---------- Hazel: the healer ----------

func _talk_hazel() -> void:
	_say_then(npcs["hazel"], func(): open_menu("Hazel's Clinic", _fill_hazel))


func _fill_hazel(m: PanelContainer) -> void:
	m.add_label("HP: %d/%d      MP: %d/%d      Gold: %d" % [GameState.hp, GameState.max_hp, GameState.mp, GameState.max_mp(), GameState.gold], UiStyle.MUTED, 16)
	m.add_button("Heal me fully  (15 gold)", _hazel_heal, GameState.gold < 15 or GameState.hp >= GameState.max_hp)
	m.add_button("Restore my mana  (10 gold)", _hazel_mana, GameState.gold < 10 or GameState.mp >= GameState.max_mp())
	m.add_button("Done", close_menu)


func _hazel_heal() -> void:
	GameState.gold -= 15
	GameState.hp = GameState.max_hp
	hud.toast("Hazel patches you right up. Fully healed!")
	refresh_menu()


func _hazel_mana() -> void:
	GameState.gold -= 10
	GameState.mp = GameState.max_mp()
	hud.toast("A warm tea and your mana is full again.")
	refresh_menu()


# ---------- Penny: a gift every day ----------

func _talk_penny() -> void:
	_say_then(npcs["penny"], _penny_gift)


func _penny_gift() -> void:
	if GameState.daily_gift_day == GameState.day:
		hud.toast("Penny: That's your gift for today. Come back tomorrow!")
		return
	GameState.daily_gift_day = GameState.day
	var r := randf()
	var gs := GameState
	if r < 0.35:
		var g := randi_range(15, 45)
		gs.gold += g
		hud.toast("Penny's daily gift: %d gold!" % g, UiStyle.BORDER)
	elif r < 0.55:
		gs.potions = mini(gs.potions + 1, gs.POTION_CAP)
		hud.toast("Penny's daily gift: a healing potion!", UiStyle.BORDER)
	elif r < 0.70:
		gs.meat = mini(gs.meat + 2, gs.FOOD_CAP)
		hud.toast("Penny's daily gift: 2 roast meats!", UiStyle.BORDER)
	elif r < 0.82:
		gs.seeds += 4
		hud.toast("Penny's daily gift: 4 crop seeds!", UiStyle.BORDER)
	elif r < 0.92:
		gs.mushrooms += 2
		hud.toast("Penny's daily gift: 2 fresh mushrooms!", UiStyle.BORDER)
	else:
		gs.mana_potions = mini(gs.mana_potions + 1, gs.POTION_CAP)
		hud.toast("Penny's daily gift: a mana potion!", UiStyle.BORDER)


# ---------- Lark: a song that powers you up ----------

func _talk_lark() -> void:
	_say_then(npcs["lark"], _lark_song)


func _lark_song() -> void:
	if GameState.bard_day == GameState.day:
		hud.toast("Lark: My voice needs a rest. Come back tomorrow for another song!")
		return
	GameState.bard_day = GameState.day
	var kind := "rage" if randf() < 0.5 else "swift"
	GameState.add_buff(kind)
	hud.toast("Lark plays a rousing tune! " + PowerupScript.NAMES[kind], UiStyle.BORDER)


# ---------- Dusty's shooting gallery ----------

func _build_gallery_booth() -> void:
	var booth := Node2D.new()
	booth.set_script(StallScript)
	booth.position = Vector2(33 * 16 + 8, 28 * 16)
	world.add_child(booth)
	add_blocker(booth, Rect2(-14, -12, 28, 12))
	for dx in [-34.0, 34.0]:
		var board := Node2D.new()
		board.position = booth.position + Vector2(dx, 4)
		var s := Sprite2D.new()
		s.texture = PixelArt.target(dx > 0.0)
		s.centered = false
		s.position = Vector2(-17, -34)
		board.add_child(s)
		var post := ColorRect.new()
		post.color = Color("5a3b1e")
		post.position = Vector2(-1, -2)
		post.size = Vector2(3, 8)
		board.add_child(post)
		world.add_child(board)
	_label("Shooting Gallery", booth.position + Vector2(0, -38))
	var dusty := _add_npc("dusty", "Dusty", 111, booth.position + Vector2(0, -5), 0.0, Color(1.15, 1.0, 0.75))
	dusty.set_meta("no_blocker", true)
	add_interactable(booth, 34.0, _talk_dusty)


func _talk_dusty() -> void:
	_say_then(npcs["dusty"], func(): open_menu("Dusty's Shooting Gallery", _fill_dusty))


func _fill_dusty(m: PanelContainer) -> void:
	m.add_label("12 arrows a round. Bullseye 5, inner ring 3, outer ring 1, golden targets 10!", UiStyle.CREAM, 16)
	m.add_label("Prize: 3 gold per point.  20+ points: a bonus potion.  30+ points: the Feathered Cap!", UiStyle.MUTED, 15)
	m.add_label("Your best score: %d" % GameState.gallery_best, UiStyle.BORDER, 16)
	m.add_button("Play a round  (10 gold)", _start_gallery, GameState.gold < 10)
	m.add_button("Done", close_menu)


func _start_gallery() -> void:
	GameState.gold -= 10
	close_menu()
	freeze(true)
	gallery.begin()


func _on_gallery_finished(score: int) -> void:
	freeze(false)
	var prize := score * 3
	GameState.gold += prize
	var lines: Array = ["You scored %d points!" % score, "Prize money: %d gold." % prize]
	if score > GameState.gallery_best:
		GameState.gallery_best = score
		lines.append("That's a new personal best!")
	if score >= 20:
		GameState.potions = mini(GameState.potions + 1, GameState.POTION_CAP)
		lines.append("Twenty or more! Have a healing potion on the house.")
		var q := Quests.event("gallery")
		if q != "":
			lines.append(q)
	if score >= 30 and not "archer" in GameState.hats:
		GameState.hats.append("archer")
		GameState.hat = "archer"
		GameState.equipment_changed.emit()
		lines.append("THIRTY! You've won the Feathered Cap. Wear it with pride!")
	hud.say("Dusty", lines)
