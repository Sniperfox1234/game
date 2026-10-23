extends Node

signal day_changed(day: int)

const DAY_LENGTH := 120.0
const MORNING := 0.25
const SAVE_PATH := "user://save.json"
const SEED_PRICE := 5
const CROP_PRICE := 12

var player_name := "Hero"
var skin_color := Color("f1c27d")
var hair_color := Color("1a1a1a")
var shirt_color := Color("4f9dde")

var day := 1
var time_of_day := MORNING # 0..1, so 0.25 is 6am
var seeds := 5
var crops := 0
var gold := 0
var plot_data: Array = [] # [[state, age], ...], written by the farm before saving
var plots_day := 1 # the day the stored plots are up to date for
var max_hp := 10
var hp := 10
var damage := 1
var quests: Dictionary = {}
var flags: Dictionary = {}
var next_spawn := "" # where the next scene should place the player


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


# Sells every crop; returns the gold earned.
func sell_crops() -> int:
	var earned := crops * CROP_PRICE
	gold += earned
	crops = 0
	return earned


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
	return true


func _next_day() -> void:
	day += 1
	day_changed.emit(day)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
