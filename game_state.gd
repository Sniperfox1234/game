extends Node

signal day_changed(day: int)
signal equipment_changed

const Outfits := preload("res://outfits.gd")

const DAY_LENGTH := 120.0
const MORNING := 0.25
const SAVE_PATH := "user://save.json"
const SEED_PRICE := 5
const CROP_PRICE := 12
const FISH_PRICE := 9
const SHROOM_PRICE := 6
const POTION_PRICE := 20
const MAX_DAMAGE := 5
const MAX_HP_CAP := 40
const PET_LEVEL := 3
const PET_PRICE := 100
const POTION_CAP := 9

var player_name := "Hero"
var skin_color := Color("f1c27d")
var hair_color := Color("1a1a1a")
var shirt_color := Color("4f9dde")

var day := 1
var time_of_day := MORNING # 0..1, so 0.25 is 6am
var seeds := 5
var crops := 0
var gold := 0
var fish := 0
var mushrooms := 0
var potions := 0
var cave_floor := 1
var level := 1
var xp := 0
var wood := 0
var stone := 0
var house_tier := 1
var pet := "" # "dog", "bat" or "ghost"; "" for none
var hats: Array = []
var hat := ""
var armors: Array = []
var armor := ""
var plot_data: Array = [] # [[state, age], ...], written by the farm before saving
var plots_day := 1 # the day the stored plots are up to date for
var max_hp := 10
var hp := 10
var damage := 1
var quests: Dictionary = {}
var flags: Dictionary = {}
var next_spawn := "" # where the next scene should place the player


func _ready() -> void:
	_add_keys("dash", [KEY_SHIFT])
	_add_keys("attack", [KEY_X, KEY_J])
	_add_keys("potion", [KEY_Q])


func _add_keys(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)


func _process(delta: float) -> void:
	time_of_day += delta / DAY_LENGTH
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		_next_day()


func start_new_game() -> void:
	day = 1
	time_of_day = MORNING
	seeds = 5
	crops = 0
	gold = 0
	fish = 0
	mushrooms = 0
	potions = 0
	cave_floor = 1
	level = 1
	xp = 0
	wood = 0
	stone = 0
	house_tier = 1
	pet = ""
	hats = []
	hat = ""
	armors = []
	armor = ""
	plot_data = []
	plots_day = 1
	max_hp = 10
	hp = 10
	damage = 1
	quests = {}
	flags = {}
	next_spawn = ""


func sleep() -> void:
	time_of_day = MORNING
	hp = max_hp
	_next_day()


func buy_seed() -> bool:
	if gold < SEED_PRICE:
		return false
	gold -= SEED_PRICE
	seeds += 1
	return true


# Sells crops, fish and mushrooms; returns the gold earned.
func sell_all() -> int:
	var earned := sale_value()
	gold += earned
	crops = 0
	fish = 0
	mushrooms = 0
	return earned


func sale_value() -> int:
	return crops * CROP_PRICE + fish * FISH_PRICE + mushrooms * SHROOM_PRICE


func buy_potion() -> bool:
	if gold < POTION_PRICE:
		return false
	gold -= POTION_PRICE
	potions += 1
	return true


func use_potion() -> bool:
	if potions <= 0 or hp >= max_hp:
		return false
	potions -= 1
	heal(5)
	return true


func sword_cost() -> int:
	return 50 * damage


func upgrade_sword() -> bool:
	if damage >= MAX_DAMAGE or gold < sword_cost():
		return false
	gold -= sword_cost()
	damage += 1
	return true


func charm_cost() -> int:
	return 40 + 20 * floori((max_hp - 10) / 2.0)


func buy_charm() -> bool:
	if max_hp >= MAX_HP_CAP or gold < charm_cost():
		return false
	gold -= charm_cost()
	max_hp += 2
	hp += 2
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"name": player_name,
		"skin": skin_color.to_html(false),
		"hair": hair_color.to_html(false),
		"shirt": shirt_color.to_html(false),
		"day": day,
		"time": time_of_day,
		"seeds": seeds,
		"crops": crops,
		"gold": gold,
		"fish": fish,
		"mushrooms": mushrooms,
		"potions": potions,
		"max_hp": max_hp,
		"level": level,
		"xp": xp,
		"wood": wood,
		"stone": stone,
		"house_tier": house_tier,
		"pet": pet,
		"hats": hats,
		"hat": hat,
		"armors": armors,
		"armor": armor,
		"plots": plot_data,
		"plots_day": plots_day,
		"hp": hp,
		"damage": damage,
		"quests": quests,
		"flags": flags,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	player_name = d.get("name", "Hero")
	skin_color = Color(d.get("skin", skin_color.to_html(false)))
	hair_color = Color(d.get("hair", hair_color.to_html(false)))
	shirt_color = Color(d.get("shirt", shirt_color.to_html(false)))
	day = int(d.get("day", 1))
	time_of_day = float(d.get("time", MORNING))
	seeds = int(d.get("seeds", 5))
	crops = int(d.get("crops", 0))
	gold = int(d.get("gold", 0))
	fish = int(d.get("fish", 0))
	mushrooms = int(d.get("mushrooms", 0))
	potions = int(d.get("potions", 0))
	max_hp = int(d.get("max_hp", 10))
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	wood = int(d.get("wood", 0))
	stone = int(d.get("stone", 0))
	house_tier = int(d.get("house_tier", 1))
	pet = d.get("pet", "")
	hats = d.get("hats", [])
	hat = d.get("hat", "")
	armors = d.get("armors", [])
	armor = d.get("armor", "")
	plot_data = d.get("plots", [])
	plots_day = int(d.get("plots_day", day))
	hp = int(d.get("hp", max_hp))
	damage = int(d.get("damage", 1))
	flags = d.get("flags", {})
	quests = {}
	for id in d.get("quests", {}):
		var q: Dictionary = d["quests"][id]
		quests[id] = {"state": q.get("state", "active"), "progress": int(q.get("progress", 0))}
	next_spawn = ""
	cave_floor = 1
	return true


func _next_day() -> void:
	day += 1
	day_changed.emit(day)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)


func defense() -> int:
	return Outfits.ARMOR[armor].def if armor != "" else 0


# Buys the hat if you don't own it (and equips it); otherwise toggles it on or off.
# Returns an error message, or "" on success.
func toggle_hat(id: String) -> String:
	if not id in hats:
		var price: int = Outfits.HATS[id].price
		if gold < price:
			return "Not enough gold!"
		gold -= price
		hats.append(id)
		hat = id
	else:
		hat = "" if hat == id else id
	equipment_changed.emit()
	return ""


func toggle_armor(id: String) -> String:
	if not id in armors:
		var price: int = Outfits.ARMOR[id].price
		if gold < price:
			return "Not enough gold!"
		gold -= price
		armors.append(id)
		armor = id
	else:
		armor = "" if armor == id else id
	equipment_changed.emit()
	return ""


func xp_needed() -> int:
	return 15 + 10 * level


# Adds XP and returns how many levels were gained. Each level gives +1 max HP and a full heal.
func add_xp(amount: int) -> int:
	xp += amount
	var gained := 0
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		gained += 1
		max_hp = mini(max_hp + 1, MAX_HP_CAP)
		hp = max_hp
	return gained


func pet_damage() -> int:
	match pet:
		"bat":
			return 1 + floori(level / 5.0)
		"ghost":
			return 1 + floori(level / 3.0)
	return 1 + floori(level / 3.0)


# Potions found in the pantry each morning, depending on how grand the house is.
func house_potions() -> int:
	return maxi(house_tier - 1, 0)
