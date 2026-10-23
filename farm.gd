extends "res://area.gd"
# The home farm: house, crop plots, a pond, a market stall, and the road east to Mossbrook.

const PlotScript := preload("res://plot.gd")
const StallScript := preload("res://stall.gd")
const Houses := preload("res://houses.gd")

# Kenney Tiny Town tile indices.
const GRASS := [0, 0, 0, 0, 0, 0, 0, 1, 1, 2]
const FIELD := {
	"tl": 12, "t": 13, "tr": 14,
	"l": 24, "c": 25, "r": 26,
	"bl": 36, "b": 37, "br": 38,
}
const ROAD_TILE := 40
const FIELD_RECT := Rect2i(13, 12, 14, 8)
const HOUSE_TILE := Vector2i(17, 3)
const EAST_GAP := Rect2i(39, 12, 1, 4) # the road to town
const REACH := 26.0

var plots: Array[Node2D] = []
var door_pos := Vector2.ZERO
var leaving := false


func _ready() -> void:
	begin(TOWN)
	_build_ground()
	build_forest(EAST_GAP)
	var rows: Array = Houses.tier_data(GameState.house_tier).rows
	door_pos = build_house(Vector2i(HOUSE_TILE.x - (rows[0].size() - 4) / 2, HOUSE_TILE.y), rows)
	_build_decor()
	_build_plots()
	_build_stall()
	add_pond(Rect2i(3, 14, 6, 4))
	add_sign(Vector2(30 * 16 + 8, 13 * 16), [
		"Mossbrook town: follow the road east.",
		"Gus the guard is at the old cave at the far end of town. Bring a potion or two!",
	])
	var door := Node2D.new()
	door.position = door_pos
	world.add_child(door)
	add_interactable(door, REACH, _sleep)

	var spawn := door_pos + Vector2(0, 14)
	if GameState.next_spawn == "east":
		spawn = Vector2((map_w - 2) * 16, 14 * 16 + 8)
	GameState.next_spawn = ""
	spawn_player(spawn)
	raids = true
	finish()
	_restore_plots()

	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0].begins_with("shot="):
		_screenshot_and_quit(args[0].trim_prefix("shot="))


func _area_process(_delta: float) -> void:
	var near := _nearest_plot()
	for plot in plots:
		plot.call("set_highlight", plot == near)
	if not leaving and player.global_position.x > (map_w - 1) * 16 - 4:
		leaving = true
		_stash()
		travel(TOWN_SCENE, "west")


func _build_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in map_h:
		for x in map_w:
			set_tile(x, y, GRASS[rng.randi() % GRASS.size()])

	var f := FIELD_RECT
	for y in range(f.position.y, f.end.y):
		for x in range(f.position.x, f.end.x):
			var top := y == f.position.y
			var bottom := y == f.end.y - 1
			var left := x == f.position.x
			var right := x == f.end.x - 1
			var key := "c"
			if top:
				key = "tl" if left else ("tr" if right else "t")
			elif bottom:
				key = "bl" if left else ("br" if right else "b")
			elif left:
				key = "l"
			elif right:
				key = "r"
			set_tile(x, y, FIELD[key])

	# Dirt road east to town, and a path from the front door down to the field.
	for x in range(f.end.x, map_w):
		set_tile(x, 13, ROAD_TILE)
		set_tile(x, 14, ROAD_TILE)
	for y in range(8, f.position.y):
		set_tile(19, y, ROAD_TILE)


func _build_decor() -> void:
	for t in [Vector2i(8, 8), Vector2i(31, 9), Vector2i(9, 22), Vector2i(30, 21), Vector2i(4, 5), Vector2i(34, 5), Vector2i(12, 24), Vector2i(36, 21)]:
		add_small_tree(t)
	for t in [Vector2i(11, 14), Vector2i(29, 17), Vector2i(20, 24), Vector2i(5, 11), Vector2i(34, 24)]:
		add_mushroom(t)


func _build_plots() -> void:
	for row in 3:
		for col in 5:
			var tile := Vector2(15 + col * 2, 14 + row * 2)
			var plot := Node2D.new()
			plot.set_script(PlotScript)
			plot.position = (tile + Vector2(0.5, 0.5)) * 16
			plot.z_index = -5
			world.add_child(plot)
			plots.append(plot)
			add_interactable(plot, REACH, func(): hud.toast(plot.call("interact")))


# A little market stall east of the house. Origin is its bottom-centre.
func _build_stall() -> void:
	var stall := Node2D.new()
	stall.position = Vector2(24 * 16, 7 * 16)
	stall.set_script(StallScript)
	world.add_child(stall)
	add_blocker(stall, Rect2(-14, -12, 28, 12))
	add_interactable(stall, 34.0, open_shop)


func _sleep() -> void:
	GameState.sleep()
	var found := mini(GameState.house_potions(), GameState.POTION_CAP - GameState.potions)
	GameState.potions += found
	_save()
	hud.toast("Good morning! Game saved." + ("  You found %d potion%s in the pantry." % [found, "" if found == 1 else "s"] if found > 0 else ""))


func _stash() -> void:
	GameState.plot_data = plots.map(func(p): return p.call("get_data"))
	GameState.plots_day = GameState.day


func _save() -> void:
	_stash()
	GameState.save_game()


# Crops keep growing while the player is away, so catch up on the days that passed.
func _restore_plots() -> void:
	if GameState.plot_data.size() == plots.size():
		for i in plots.size():
			plots[i].call("set_data", GameState.plot_data[i])
		for d in maxi(GameState.day - GameState.plots_day, 0):
			for plot in plots:
				plot.call("advance_day")
	GameState.plots_day = GameState.day
	if GameState.flags.get("house_new", false):
		GameState.flags.erase("house_new")
		hud.toast("Your house has been upgraded to a %s!" % Houses.tier_data(GameState.house_tier).name)
	var lost: int = GameState.flags.get("passed_out", -1)
	if lost >= 0:
		GameState.flags.erase("passed_out")
		hud.toast("You passed out and woke up at home. Lost %d gold." % lost)


func _on_new_day(day: int) -> void:
	super(day)
	for plot in plots:
		plot.call("advance_day")
	GameState.plots_day = day
	if hud:
		hud.toast("Day %d begins!" % day)


func _nearest_plot() -> Node2D:
	var best: Node2D = null
	var best_dist := REACH
	var feet := player.global_position + Vector2(0, -2)
	for plot in plots:
		var dist := plot.global_position.distance_to(feet)
		if dist < best_dist:
			best = plot
			best_dist = dist
	return best


# Dev hook: Godot --path . -- shot=/path/out.png saves a noon screenshot and quits.
func _screenshot_and_quit(path: String) -> void:
	GameState.time_of_day = 0.5
	(player.get_node("Camera2D") as Camera2D).zoom = Vector2(1.6, 1.6)
	for i in 8:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
