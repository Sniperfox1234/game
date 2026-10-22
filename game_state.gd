extends Node

signal day_changed(day: int)

const DAY_LENGTH := 120.0
const MORNING := 0.25

var player_name := "Hero"
var skin_color := Color("f1c27d")
var hair_color := Color("1a1a1a")
var shirt_color := Color("4f9dde")

var day := 1
var time_of_day := MORNING # 0..1, so 0.25 is 6am
var seeds := 5
var crops := 0


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


func sleep() -> void:
	time_of_day = MORNING
	_next_day()


func _next_day() -> void:
	day += 1
	day_changed.emit(day)
