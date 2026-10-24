extends "res://area.gd"
# Shared base for the four regions reached by carriage: Highgarden Castle, Sunscar Desert,
# Port Saltmere and Mistmere Swamp. Adds wandering monsters, dungeon entrances and building doors.

const RegionArt := preload("res://region_art.gd")
const Weapons := preload("res://weapons.gd")

var roam_kinds: Array = []
var roam_max := 0
var roam_interval := 11.0
var roam_distance := 170.0
var _roam_timer := 6.0
var entrances := {} # dungeon id -> position (front of the entrance)
var doors := {} # interior id -> position (front door of the building)


func _area_process(delta: float) -> void:
	if traveling:
		return
	_region_tick(delta)
	_process_region(delta)


# Region scripts override this for their own per-frame work.
func _process_region(_delta: float) -> void:
	pass


func _region_tick(delta: float) -> void:
	# Doors into buildings.
	var p := player.global_position
	for id in doors:
		var d: Vector2 = doors[id]
		if absf(p.x - d.x) < 10.0 and p.y < d.y + 10.0 and p.y > d.y - 6.0:
			GameState.interior = id
			GameState.interior_exit = scene_file_path
			travel(INTERIOR_SCENE, "")
			return
	# Entrances to dungeons.
	for id in entrances:
		var e: Vector2 = entrances[id]
		if p.distance_to(e) < 14.0:
			GameState.dungeon = id
			GameState.cave_floor = 1
			travel(CAVE_SCENE, "region")
			return
	# Wild monsters wander in, a few at a time, never right on top of you.
	if roam_max > 0:
		_roam_timer -= delta
		if _roam_timer <= 0.0:
			_roam_timer = roam_interval
			if get_tree().get_nodes_in_group("roamers").size() < roam_max:
				var spot := _free_spot_away(roam_distance)
				if spot != Vector2.INF:
					var e := spawn_enemy(roam_kinds[randi() % roam_kinds.size()], spot)
					e.add_to_group("roamers")


# Fills the map with a few monsters when you arrive.
func seed_roamers(count: int) -> void:
	for i in count:
		var spot := _free_spot_away(220.0)
		if spot != Vector2.INF:
			var e := spawn_enemy(roam_kinds[randi() % roam_kinds.size()], spot)
			e.add_to_group("roamers")


func add_door_label(text: String, pos: Vector2) -> void:
	add_label(text, pos)


func paint_rect(r: Rect2i, type: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			set_terrain(x, y, type)


# A static sprite sitting on the ground. `feet` is the bottom-centre of the picture.
func add_prop(texture: Texture2D, feet: Vector2, block := Rect2(), shadow := Vector2.ZERO) -> Node2D:
	var n := Node2D.new()
	n.position = feet
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.position = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	n.add_child(s)
	world.add_child(n)
	if block.size != Vector2.ZERO:
		add_blocker(n, block)
	if shadow != Vector2.ZERO:
		SoftShadow.attach(n, shadow, Vector2(0, -2), 0.8)
	return n


func add_block_rect(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	world.add_child(body)


# Where you appear: at a building door, a dungeon mouth, or the carriage stop.
func region_spawn(carriage_stop: Vector2) -> Vector2:
	var ns := GameState.next_spawn
	var pos := carriage_stop
	if ns == "dungeon" and entrances.has(GameState.last_dungeon):
		pos = entrances[GameState.last_dungeon] + Vector2(0, 26)
	elif doors.has(ns):
		pos = doors[ns] + Vector2(0, 22)
	GameState.next_spawn = ""
	return pos


# Solid walls along every run of water tiles, so you can't wade into the moat or the sea.
func build_water_blockers() -> void:
	for y in map_h:
		var x := 0
		while x < map_w:
			if terrain_types[y * map_w + x] != 9:
				x += 1
				continue
			var start := x
			while x < map_w and terrain_types[y * map_w + x] == 9:
				x += 1
			add_block_rect(Rect2(start * 16, y * 16 + 2, (x - start) * 16, 12))


# A stretch of open water you can fish in. The terrain already draws it, so this is invisible.
func add_sea_fishing(tiles: Rect2i) -> void:
	var sea := Node2D.new()
	sea.set_script(load("res://water.gd"))
	sea.plain = true
	sea.size = Vector2(tiles.size) * 16.0
	sea.position = Vector2(tiles.position) * 16.0
	world.add_child(sea)
	add_interactable(sea, 20.0, func(): _start_fishing(sea), Rect2(sea.position, sea.size))


# Merchants: a menu with a tent's worth of weapons and a button for the clothes rack.
func open_trader(title: String, shop: String, order: Array) -> void:
	open_menu(title, func(m: PanelContainer): _fill_trader(m, shop, order))


func _fill_trader(m: PanelContainer, shop: String, order: Array) -> void:
	m.add_label("Gold: %d" % GameState.gold, UiStyle.MUTED, 16)
	for id in order:
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
		m.add_button(text, _trade_weapon.bind(id), equipped or (not owned and GameState.gold < w.price))
	m.add_button("Clothes and armour...", func():
		close_menu()
		open_outfitter(shop))
	m.add_button("Done", close_menu)


func _trade_weapon(id: String) -> void:
	var err := GameState.buy_or_equip_weapon(id)
	hud.toast(err if err != "" else "Equipped the %s!" % Weapons.WEAPONS[id].name)
	refresh_menu()


# Talk to a person: their quest first, otherwise the greeting, then whatever `then` does.
func talk_person(npc: Node2D, id: String, display: String, greeting: Array, then := Callable()) -> void:
	if Quests.active_for(id) != "":
		var t := Quests.talk(id)
		var after: Callable = t.get("after", Callable())
		hud.say(display, t.lines, func():
			if after.is_valid():
				var msg: String = after.call()
				if msg != "":
					hud.toast(msg)
			if then.is_valid():
				then.call())
	else:
		hud.say(display, greeting, then)


func open_remedies() -> void:
	open_menu("Remedies", _fill_remedies)


func _fill_remedies(m: PanelContainer) -> void:
	m.add_label("Gold: %d      HP %d/%d      MP %d/%d" % [GameState.gold, GameState.hp, GameState.max_hp, GameState.mp, GameState.max_mp()], UiStyle.MUTED, 16)
	m.add_button("Restorative Elixir  (80 gold)    full HP and mana, cures poison", _remedy_elixir, GameState.gold < 80 or (GameState.hp >= GameState.max_hp and GameState.mp >= GameState.max_mp() and GameState.poison_time <= 0.0))
	m.add_button("Antidote  (15 gold)    cures poison", _remedy_antidote, GameState.gold < 15 or GameState.poison_time <= 0.0)
	m.add_button("Done", close_menu)


func _remedy_elixir() -> void:
	GameState.gold -= 80
	GameState.hp = GameState.max_hp
	GameState.mp = GameState.max_mp()
	player.cure_poison()
	hud.toast("The elixir fills you with warmth. Fully restored!")
	Audio.sfx("potion")
	refresh_menu()


func _remedy_antidote() -> void:
	GameState.gold -= 15
	player.cure_poison()
	hud.toast("The poison is gone.")
	Audio.sfx("potion")
	refresh_menu()
