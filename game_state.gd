extends Node

signal day_changed(day: int)
signal equipment_changed

const Outfits := preload("res://outfits.gd")
const Fish := preload("res://fish.gd")
const Weapons := preload("res://weapons.gd")
const Cooking := preload("res://cooking.gd")

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
const MEAT_PRICE := 8
const MEAT_HEAL := 3
const STEAK_PRICE := 22
const STEAK_HEAL := 8
const FOOD_CAP := 9
const MANA_POTION_PRICE := 15
const MANA_POTION_HEAL := 5
const FIREBALL_PRICE := 150
const FIREBALL2_PRICE := 500
const CRYSTAL_PRICE := 120
const MAX_CRYSTALS := 3
const FIREBALL_COST := 2

var player_name := "Hero"
var skin_color := Color("f1c27d")
var hair_color := Color("1a1a1a")
var shirt_color := Color("4f9dde")

var day := 1
var time_of_day := MORNING # 0..1, so 0.25 is 6am
var seeds := 5
var crops := 0
var gold := 0
# Fish are stored by rarity so each one sells for what it is worth. `fish` is the total count,
# which is what quests ask for; setting it adds common fish or removes the cheapest ones.
var fish_stock := {"common": 0, "uncommon": 0, "rare": 0, "epic": 0, "legendary": 0}
var fish_log := {} # species name -> times caught
var fish_claimed: Array = [] # rarities whose fish-book reward was collected
var rod := 0
var bank := 0
var bank_interest := 0 # what the bank paid you most recently
var kills := {} # monster kind -> times defeated
var fish: int:
	get:
		return fish_total()
	set(v):
		_set_fish(v)
var mushrooms := 0
var potions := 0
var cave_floor := 1
var meat := 0
var steak := 0
var interior := "" # which shop interior to load next (not saved)
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
var weapons: Array = ["training"]
var weapon := "training"
var mp := 7
var mp_bonus := 0
var spell := 0 # 0 none, 1 fireball, 2 triple fireball
var mana_potions := 0
var gallery_best := 0
var daily_gift_day := 0
var bard_day := 0
var buff_rage := 0.0
var buff_swift := 0.0
var buff_aegis_time := 0.0
var aegis_hits := 0
var _mp_acc := 0.0
var meal := "" # the cooked meal currently making you "well fed"
var meal_time := 0.0
var _regen_acc := 0.0
var quests: Dictionary = {}
var flags: Dictionary = {}
var next_spawn := "" # where the next scene should place the player


func _ready() -> void:
	_add_keys("dash", [KEY_SHIFT])
	_add_keys("attack", [KEY_X, KEY_J])
	_add_keys("potion", [KEY_Q])
	_add_keys("eat", [KEY_E])
	_add_keys("fireball", [KEY_F])
	_add_keys("mana", [KEY_M])


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
	buff_rage = maxf(buff_rage - delta, 0.0)
	buff_swift = maxf(buff_swift - delta, 0.0)
	if buff_aegis_time > 0.0:
		buff_aegis_time -= delta
		if buff_aegis_time <= 0.0:
			aegis_hits = 0
	if meal_time > 0.0:
		meal_time -= delta
		var regen: float = meal_data().get("regen", 0.0)
		if regen > 0.0 and hp < max_hp:
			_regen_acc += delta
			if _regen_acc >= regen:
				_regen_acc = 0.0
				heal(1)
		if meal_time <= 0.0:
			meal = ""
	if mp < max_mp():
		_mp_acc += delta * float(meal_data().get("mana", 1.0))
		if _mp_acc >= 2.5:
			_mp_acc = 0.0
			mp += 1


func start_new_game() -> void:
	day = 1
	time_of_day = MORNING
	seeds = 5
	crops = 0
	gold = 0
	fish_stock = {"common": 0, "uncommon": 0, "rare": 0, "epic": 0, "legendary": 0}
	fish_log = {}
	fish_claimed = []
	rod = 0
	bank = 0
	bank_interest = 0
	kills = {}
	mushrooms = 0
	potions = 0
	cave_floor = 1
	meat = 0
	steak = 0
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
	weapons = ["training"]
	weapon = "training"
	mp_bonus = 0
	spell = 0
	mana_potions = 0
	gallery_best = 0
	daily_gift_day = 0
	bard_day = 0
	buff_rage = 0.0
	buff_swift = 0.0
	buff_aegis_time = 0.0
	aegis_hits = 0
	meal = ""
	meal_time = 0.0
	mp = max_mp()
	quests = {}
	flags = {}
	next_spawn = ""
	Audio.sync_gold()


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
	for r in Fish.RARITIES:
		fish_stock[r] = 0
	mushrooms = 0
	return earned


func fish_total() -> int:
	var n := 0
	for r in Fish.RARITIES:
		n += int(fish_stock[r])
	return n


func fish_value() -> int:
	var v := 0
	for r in Fish.RARITIES:
		v += int(fish_stock[r]) * Fish.price(r)
	return v


func _set_fish(v: int) -> void:
	var diff := v - fish_total()
	if diff > 0:
		fish_stock["common"] += diff
		return
	for r in Fish.RARITIES:
		while diff < 0 and fish_stock[r] > 0:
			fish_stock[r] -= 1
			diff += 1


# Records a catch; returns true if this species is new to the fish book.
func record_catch(species: String, rarity: String) -> bool:
	var is_new := not fish_log.has(species)
	fish_log[species] = int(fish_log.get(species, 0)) + 1
	fish_stock[rarity] += 1
	return is_new


# Rarities whose species have all been caught and whose reward hasn't been collected yet.
func book_rewards_ready() -> Array:
	var out: Array = []
	for r in Fish.RARITIES:
		if r in fish_claimed:
			continue
		var complete := true
		for s in Fish.INFO[r].species:
			if not fish_log.has(s):
				complete = false
		if complete:
			out.append(r)
	return out


func sale_value() -> int:
	return crops * CROP_PRICE + fish_value() + mushrooms * SHROOM_PRICE


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
		"fish_stock": fish_stock,
		"fish_log": fish_log,
		"fish_claimed": fish_claimed,
		"rod": rod,
		"bank": bank,
		"bank_interest": bank_interest,
		"kills": kills,
		"weapons": weapons,
		"weapon": weapon,
		"mp": mp,
		"mp_bonus": mp_bonus,
		"spell": spell,
		"mana_potions": mana_potions,
		"gallery_best": gallery_best,
		"daily_gift_day": daily_gift_day,
		"bard_day": bard_day,
		"mushrooms": mushrooms,
		"potions": potions,
		"max_hp": max_hp,
		"meat": meat,
		"steak": steak,
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
	fish_stock = {"common": 0, "uncommon": 0, "rare": 0, "epic": 0, "legendary": 0}
	var saved_stock: Dictionary = d.get("fish_stock", {})
	for r in Fish.RARITIES:
		fish_stock[r] = int(saved_stock.get(r, 0))
	if d.has("fish") and not d.has("fish_stock"):
		fish_stock["common"] = int(d["fish"]) # from an older save
	fish_log = {}
	for s in d.get("fish_log", {}):
		fish_log[s] = int(d["fish_log"][s])
	fish_claimed = d.get("fish_claimed", [])
	rod = int(d.get("rod", 0))
	bank = int(d.get("bank", 0))
	bank_interest = int(d.get("bank_interest", 0))
	kills = {}
	for k in d.get("kills", {}):
		kills[k] = int(d["kills"][k])
	weapons = d.get("weapons", ["training"])
	weapon = d.get("weapon", "training")
	mp_bonus = int(d.get("mp_bonus", 0))
	spell = int(d.get("spell", 0))
	mana_potions = int(d.get("mana_potions", 0))
	gallery_best = int(d.get("gallery_best", 0))
	daily_gift_day = int(d.get("daily_gift_day", 0))
	bard_day = int(d.get("bard_day", 0))
	mushrooms = int(d.get("mushrooms", 0))
	potions = int(d.get("potions", 0))
	max_hp = int(d.get("max_hp", 10))
	meat = int(d.get("meat", 0))
	steak = int(d.get("steak", 0))
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
	# The Slimeblade used to be a flat +3 damage flag; it is a weapon now.
	if flags.get("slimeblade", false) and not "slimeblade" in weapons:
		weapons.append("slimeblade")
		weapon = "slimeblade"
		damage = maxi(damage - 3, 1)
	mp = mini(int(d.get("mp", max_mp())), max_mp())
	next_spawn = ""
	cave_floor = 1
	Audio.sync_gold()
	return true


func _next_day() -> void:
	# The town treasury pays 5% a day on your savings, up to 30 gold.
	bank_interest = mini(floori(bank * 0.05), 30)
	bank += bank_interest
	day += 1
	day_changed.emit(day)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)


func defense() -> int:
	return (Outfits.ARMOR[armor].def if armor != "" else 0) + int(meal_data().get("def", 0))


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
		mp = max_mp()
	if gained > 0:
		Audio.sfx("levelup")
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


func buy_meat() -> bool:
	if gold < MEAT_PRICE or meat >= FOOD_CAP:
		return false
	gold -= MEAT_PRICE
	meat += 1
	return true


func buy_steak() -> bool:
	if gold < STEAK_PRICE or steak >= FOOD_CAP:
		return false
	gold -= STEAK_PRICE
	steak += 1
	return true


# Eats whichever food wastes the least healing. Returns HP restored, -1 if already at full
# health, or -2 if you have nothing to eat.
func eat() -> int:
	if meat <= 0 and steak <= 0:
		return -2
	if hp >= max_hp:
		return -1
	var missing := max_hp - hp
	var use_steak := steak > 0 and (meat <= 0 or missing >= STEAK_HEAL)
	var amount := STEAK_HEAL if use_steak else MEAT_HEAL
	if use_steak:
		steak -= 1
	else:
		meat -= 1
	var before := hp
	heal(amount)
	return hp - before


# ---------- weapons, spells and power-ups ----------

func weapon_data() -> Dictionary:
	return Weapons.WEAPONS[weapon]


# Damage of one sword swing: sharpening level plus the weapon's bonus, boosted by Rage.
func attack_damage() -> int:
	var base := damage + int(weapon_data().dmg) + int(meal_data().get("dmg", 0))
	return ceili(base * 1.5) if buff_rage > 0.0 else base


# Buys the weapon if you don't own it, then equips it. Returns an error message or "".
func buy_or_equip_weapon(id: String) -> String:
	if not id in weapons:
		var price: int = Weapons.WEAPONS[id].price
		if gold < price:
			return "Not enough gold!"
		gold -= price
		weapons.append(id)
	weapon = id
	return ""


func max_mp() -> int:
	return 6 + level + mp_bonus


func use_mp(amount: int) -> bool:
	if mp < amount:
		return false
	mp -= amount
	return true


func buy_fireball() -> bool:
	if spell >= 1 or gold < FIREBALL_PRICE:
		return false
	gold -= FIREBALL_PRICE
	spell = 1
	return true


func buy_fireball2() -> bool:
	if spell != 1 or gold < FIREBALL2_PRICE:
		return false
	gold -= FIREBALL2_PRICE
	spell = 2
	return true


func buy_crystal() -> bool:
	if mp_bonus >= MAX_CRYSTALS * 3 or gold < CRYSTAL_PRICE:
		return false
	gold -= CRYSTAL_PRICE
	mp_bonus += 3
	mp += 3
	return true


func buy_mana_potion() -> bool:
	if gold < MANA_POTION_PRICE or mana_potions >= POTION_CAP:
		return false
	gold -= MANA_POTION_PRICE
	mana_potions += 1
	return true


func drink_mana() -> int:
	if mana_potions <= 0:
		return -2
	if mp >= max_mp():
		return -1
	mana_potions -= 1
	var before := mp
	mp = mini(mp + MANA_POTION_HEAL, max_mp())
	return mp - before


func fireball_damage() -> int:
	return 2 + floori(level / 3.0)


func add_buff(kind: String) -> void:
	match kind:
		"rage":
			buff_rage = 15.0
		"swift":
			buff_swift = 15.0
		"aegis":
			aegis_hits = 3
			buff_aegis_time = 20.0
		"heart":
			heal(3)


# ---------- bank ----------

func deposit(amount: int) -> int:
	var n := mini(amount, gold)
	gold -= n
	bank += n
	return n


func withdraw(amount: int) -> int:
	var n := mini(amount, bank)
	bank -= n
	gold += n
	return n


# ---------- cooking ----------

func meal_data() -> Dictionary:
	return Cooking.MEALS[meal] if meal != "" and meal_time > 0.0 else {}


func is_swift() -> bool:
	return buff_swift > 0.0 or meal_data().get("swift", false)


func start_meal(id: String) -> void:
	meal = id
	meal_time = float(Cooking.MEALS[id].dur)
	_regen_acc = 0.0


# How many fish you have of this rarity or better.
func fish_at_least(rarity: String) -> int:
	var n := 0
	for r in range(Fish.RARITIES.find(rarity), Fish.RARITIES.size()):
		n += int(fish_stock[Fish.RARITIES[r]])
	return n


# Removes the cheapest `count` fish of at least this rarity.
func take_fish_at_least(rarity: String, count: int) -> void:
	for r in range(Fish.RARITIES.find(rarity), Fish.RARITIES.size()):
		var key: String = Fish.RARITIES[r]
		while count > 0 and fish_stock[key] > 0:
			fish_stock[key] -= 1
			count -= 1
