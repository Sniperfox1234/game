extends CanvasLayer
# Shared overlay for the town and the cave: stats, health bar, quest tracker, toast, dialogue box.

signal dialogue_changed(active: bool)

const Quests := preload("res://quests.gd")
const UiStyle := preload("res://ui_style.gd")
const CHARS_PER_SEC := 60.0
const BAR_W := 160.0
const BOSS_W := 520.0

var hint := ""

var stats := Label.new()
var tracker := Label.new()
var toast_label := Label.new()
var toast_box := PanelContainer.new()
var speaker_tag := PanelContainer.new()
var boss_box := PanelContainer.new()
var boss_name := Label.new()
var boss_fill := Panel.new()
var arrow := Polygon2D.new()
var _t := 0.0
var toast_time := 0.0
var hp_fill := Panel.new()
var mp_fill := Panel.new()
var inventory := Label.new()
var buffs := Label.new()
var box := PanelContainer.new()
var speaker_label := Label.new()
var text_label := Label.new()
var lines: Array = []
var line_idx := 0
var on_done := Callable()
var reveal := 0.0
var _blips := 0


func _ready() -> void:
	layer = 2
	_style(stats, 20)
	stats.position = Vector2(16, 12)
	add_child(stats)

	var hp_back := Panel.new()
	hp_back.add_theme_stylebox_override("panel", _bar_style(Color("2a2540"), UiStyle.BORDER, 2))
	hp_back.position = Vector2(16, 108)
	hp_back.size = Vector2(BAR_W + 8, 18)
	add_child(hp_back)
	hp_fill.add_theme_stylebox_override("panel", _bar_style(Color("e84a5f"), Color("ff8a9a"), 0))
	hp_fill.position = Vector2(20, 112)
	hp_fill.size = Vector2(BAR_W, 10)
	add_child(hp_fill)

	var mp_back := Panel.new()
	mp_back.add_theme_stylebox_override("panel", _bar_style(Color("1d2540"), Color("7fa8e8"), 2))
	mp_back.position = Vector2(16, 130)
	mp_back.size = Vector2(BAR_W + 8, 14)
	add_child(mp_back)
	mp_fill.add_theme_stylebox_override("panel", _bar_style(Color("3f7fe0"), Color("9fc8ff"), 0))
	mp_fill.position = Vector2(20, 134)
	mp_fill.size = Vector2(BAR_W, 6)
	add_child(mp_fill)

	_style(inventory, 15)
	inventory.position = Vector2(16, 152)
	add_child(inventory)
	_style(buffs, 17)
	buffs.position = Vector2(16, 174)
	buffs.add_theme_color_override("font_color", Color("ffd966"))
	add_child(buffs)

	_style(tracker, 18)
	tracker.position = Vector2(760, 12)
	tracker.size = Vector2(380, 100)
	tracker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(tracker)

	# Toast: a rounded pill at the bottom left that only shows while it has text.
	toast_label.add_theme_font_size_override("font_size", 20)
	toast_label.add_theme_color_override("font_color", UiStyle.CREAM)
	toast_box.add_theme_stylebox_override("panel", UiStyle.pill(UiStyle.BG))
	toast_box.add_child(toast_label)
	toast_box.position = Vector2(16, 584)
	toast_box.visible = false
	add_child(toast_box)

	# Dialogue: a rounded panel with a name tag perched on its top-left corner.
	var inner := VBoxContainer.new()
	text_label.add_theme_font_size_override("font_size", 22)
	text_label.add_theme_color_override("font_color", UiStyle.CREAM)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(880, 72)
	inner.add_child(text_label)
	box.add_theme_stylebox_override("panel", UiStyle.panel(18))
	box.add_child(inner)
	box.position = Vector2(108, 488)
	box.visible = false
	add_child(box)

	speaker_label.add_theme_font_size_override("font_size", 20)
	speaker_label.add_theme_color_override("font_color", Color("2a2118"))
	speaker_tag.add_theme_stylebox_override("panel", UiStyle.pill(UiStyle.BORDER, Color("fff3c4")))
	speaker_tag.add_child(speaker_label)
	speaker_tag.position = Vector2(140, 462)
	speaker_tag.visible = false
	add_child(speaker_tag)

	# Boss mode: a big health bar at the bottom of the screen while a boss is alive.
	var boss_inner := VBoxContainer.new()
	boss_name.text = "King Slime"
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_font_size_override("font_size", 20)
	boss_name.add_theme_color_override("font_color", UiStyle.BORDER)
	boss_inner.add_child(boss_name)
	var boss_track := Panel.new()
	boss_track.custom_minimum_size = Vector2(BOSS_W, 16)
	boss_track.add_theme_stylebox_override("panel", _bar_style(Color("2a2540"), UiStyle.BORDER, 2))
	boss_fill.add_theme_stylebox_override("panel", _bar_style(Color("c63a4e"), Color("ff8a9a"), 1))
	boss_fill.position = Vector2(3, 3)
	boss_fill.size = Vector2(BOSS_W - 6, 10)
	boss_track.add_child(boss_fill)
	boss_inner.add_child(boss_track)
	boss_box.add_theme_stylebox_override("panel", UiStyle.pill(UiStyle.BG))
	boss_box.add_child(boss_inner)
	boss_box.position = Vector2((1152 - BOSS_W) / 2.0 - 20.0, 566)
	boss_box.visible = false
	add_child(boss_box)

	arrow.polygon = PackedVector2Array([Vector2(-7, -5), Vector2(7, -5), Vector2(0, 5)])
	arrow.color = UiStyle.BORDER
	arrow.visible = false
	add_child(arrow)


func _bar_style(bg: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(9)
	s.anti_aliasing = true
	return s


func _style(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)


func busy() -> bool:
	return box.visible


func toast(text: String, color: Color = UiStyle.CREAM) -> void:
	toast_label.add_theme_color_override("font_color", color)
	toast_label.text = text
	toast_box.visible = text != ""
	toast_box.size = Vector2.ZERO
	toast_time = 2.8


func say(speaker: String, new_lines: Array, done: Callable = Callable()) -> void:
	lines = new_lines
	line_idx = 0
	on_done = done
	speaker_label.text = speaker
	_show_line()
	box.visible = true
	speaker_tag.visible = true
	speaker_tag.size = Vector2.ZERO
	Audio.sfx("open")
	dialogue_changed.emit(true)


func _show_line() -> void:
	_blips = 0
	text_label.text = lines[line_idx]
	text_label.visible_characters = 0
	reveal = 0.0


func _process(delta: float) -> void:
	var minutes := int(GameState.time_of_day * 24.0 * 60.0)
	var gear: Array[String] = ["Weapon: %s" % GameState.weapon_data().name]
	if GameState.defense() > 0:
		gear.append("Def %d" % GameState.defense())
	if GameState.meat > 0:
		gear.append("Meat %d" % GameState.meat)
	if GameState.steak > 0:
		gear.append("Steak %d" % GameState.steak)
	if GameState.mana_potions > 0:
		gear.append("Mana pots %d" % GameState.mana_potions)
	if GameState.fish > 0:
		gear.append("Fish %d" % GameState.fish)
	if GameState.wood > 0:
		gear.append("Wood %d" % GameState.wood)
	if GameState.stone > 0:
		gear.append("Stone %d" % GameState.stone)
	inventory.text = "   ".join(gear)
	var active: Array[String] = []
	if GameState.buff_rage > 0.0:
		active.append("RAGE %ds" % ceili(GameState.buff_rage))
	if GameState.buff_swift > 0.0:
		active.append("SWIFT %ds" % ceili(GameState.buff_swift))
	if GameState.aegis_hits > 0:
		active.append("AEGIS x%d" % GameState.aegis_hits)
	if GameState.poison_time > 0.0:
		active.append("POISONED %ds" % ceili(GameState.poison_time))
	if GameState.meal_time > 0.0:
		active.append("%s %ds" % [GameState.meal_data().name.to_upper(), ceili(GameState.meal_time)])
	buffs.text = "   ".join(active)
	stats.text = "%s  Lv %d (%d/%d XP) - Day %d  %02d:%02d\nGold: %d   HP: %d/%d   MP: %d/%d   Potions: %d\n%s" % [
		GameState.player_name, GameState.level, GameState.xp, GameState.xp_needed(),
		GameState.day, floori(minutes / 60.0), minutes % 60,
		GameState.gold, GameState.hp, GameState.max_hp, GameState.mp, GameState.max_mp(), GameState.potions, hint,
	]
	mp_fill.size.x = maxf(BAR_W * clampf(float(GameState.mp) / GameState.max_mp(), 0.0, 1.0), 6.0)
	mp_fill.visible = GameState.mp > 0
	var frac := clampf(float(GameState.hp) / GameState.max_hp, 0.0, 1.0)
	hp_fill.size.x = maxf(BAR_W * frac, 10.0)
	hp_fill.visible = GameState.hp > 0
	tracker.text = Quests.tracker_text()

	var boss: Node = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("boss"):
			boss = e
			break
	boss_box.visible = boss != null
	if boss != null:
		boss_name.text = boss.display_name
	toast_box.position.y = 520.0 if boss != null else 584.0
	if boss != null:
		boss_fill.size.x = maxf((BOSS_W - 6.0) * clampf(float(boss.hp) / boss.max_hp, 0.0, 1.0), 6.0)

	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast_label.text = ""
			toast_box.visible = false
	if box.visible:
		reveal += delta * CHARS_PER_SEC
		text_label.visible_characters = int(reveal)
		if int(reveal) / 2 > _blips and int(reveal) < text_label.text.length():
			_blips = int(reveal) / 2
			Audio.sfx("blip", 0.25)
		_t += delta
		var done := int(reveal) >= text_label.text.length()
		arrow.visible = done
		arrow.position = box.position + box.size - Vector2(34, 26 - sin(_t * 6.0) * 2.0)


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
	speaker_tag.visible = false
	arrow.visible = false
	dialogue_changed.emit(false)
	if on_done.is_valid():
		on_done.call()
