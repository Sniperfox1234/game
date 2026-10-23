extends CanvasLayer
# Shared overlay for the town and the cave: stats, health bar, quest tracker, toast, dialogue box.

signal dialogue_changed(active: bool)

const Quests := preload("res://quests.gd")
const CHARS_PER_SEC := 60.0
const BAR_W := 160.0

var hint := ""

var stats := Label.new()
var tracker := Label.new()
var toast_label := Label.new()
var toast_time := 0.0
var hp_fill := ColorRect.new()
var box := PanelContainer.new()
var speaker_label := Label.new()
var text_label := Label.new()
var lines: Array = []
var line_idx := 0
var on_done := Callable()
var reveal := 0.0


func _ready() -> void:
	_style(stats, 20)
	stats.position = Vector2(16, 12)
	add_child(stats)

	var hp_back := ColorRect.new()
	hp_back.color = Color("2e2233")
	hp_back.position = Vector2(16, 108)
	hp_back.size = Vector2(BAR_W + 4, 16)
	add_child(hp_back)
	hp_fill.color = Color("e84a5f")
	hp_fill.position = Vector2(18, 110)
	hp_fill.size = Vector2(BAR_W, 12)
	add_child(hp_fill)

	_style(tracker, 18)
	tracker.position = Vector2(760, 12)
	tracker.size = Vector2(380, 100)
	tracker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(tracker)

	_style(toast_label, 22)
	toast_label.position = Vector2(16, 590)
	add_child(toast_label)

	var inner := VBoxContainer.new()
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.add_theme_color_override("font_color", Color("f2c14e"))
	inner.add_child(speaker_label)
	text_label.add_theme_font_size_override("font_size", 22)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(900, 70)
	inner.add_child(text_label)
	var prompt := Label.new()
	prompt.text = "Space to continue"
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.modulate = Color(1, 1, 1, 0.6)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inner.add_child(prompt)
	box.add_child(inner)
	box.position = Vector2(96, 470)
	box.visible = false
	add_child(box)


func _style(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)


func busy() -> bool:
	return box.visible


func toast(text: String) -> void:
	toast_label.text = text
	toast_time = 2.8


func say(speaker: String, new_lines: Array, done: Callable = Callable()) -> void:
	lines = new_lines
	line_idx = 0
	on_done = done
	speaker_label.text = speaker
	_show_line()
	box.visible = true
	dialogue_changed.emit(true)


func _show_line() -> void:
	text_label.text = lines[line_idx]
	text_label.visible_characters = 0
	reveal = 0.0


func _process(delta: float) -> void:
	var minutes := int(GameState.time_of_day * 24.0 * 60.0)
	stats.text = "%s - Day %d  %02d:%02d\nGold: %d   HP: %d/%d   Potions: %d\n%s" % [
		GameState.player_name, GameState.day, floori(minutes / 60.0), minutes % 60,
		GameState.gold, GameState.hp, GameState.max_hp, GameState.potions, hint,
	]
	hp_fill.size.x = BAR_W * clampf(float(GameState.hp) / GameState.max_hp, 0.0, 1.0)
	tracker.text = Quests.tracker_text()

	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast_label.text = ""
	if box.visible:
		reveal += delta * CHARS_PER_SEC
		text_label.visible_characters = int(reveal)


func _unhandled_input(event: InputEvent) -> void:
	if not box.visible or not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	if int(reveal) < text_label.text.length():
		reveal = text_label.text.length()
		return
	line_idx += 1
	if line_idx < lines.size():
		_show_line()
		return
	box.visible = false
	dialogue_changed.emit(false)
	if on_done.is_valid():
		on_done.call()
