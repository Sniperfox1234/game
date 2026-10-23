extends Control

const AvatarScript := preload("res://avatar.gd")

const SKIN := ["f8d8b8", "f1c27d", "e0ac69", "c68642", "8d5524", "5c3a1e"]
const HAIR := ["1a1a1a", "4a2c17", "8b5a2b", "d9b44a", "c0392b", "6c8ebf"]
const SHIRT := ["4f9dde", "e86a6a", "6abf69", "f2c14e", "a66cd8", "f5f5f5"]

var avatar := Node2D.new()
var name_edit := LineEdit.new()


func _ready() -> void:
	Audio.music("mus_farm")
	Audio.ambience("")
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color("2b3a55")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Create your hero"
	title.add_theme_font_size_override("font_size", 32)
	title.position = Vector2(60, 40)
	add_child(title)

	avatar.set_script(AvatarScript)
	avatar.position = Vector2(300, 440)
	avatar.scale = Vector2(8, 8)
	add_child(avatar)

	var panel := VBoxContainer.new()
	panel.position = Vector2(620, 130)
	panel.add_theme_constant_override("separation", 18)
	add_child(panel)

	var name_label := Label.new()
	name_label.text = "Name"
	panel.add_child(name_label)
	name_edit.text = GameState.player_name
	name_edit.max_length = 16
	name_edit.custom_minimum_size = Vector2(300, 36)
	panel.add_child(name_edit)

	panel.add_child(_swatch_row("Skin", SKIN, _set_skin))
	panel.add_child(_swatch_row("Hair", HAIR, _set_hair))
	panel.add_child(_swatch_row("Outfit", SHIRT, _set_shirt))

	var start := Button.new()
	start.text = "Start adventure"
	start.custom_minimum_size = Vector2(300, 48)
	start.pressed.connect(_on_start)
	panel.add_child(start)

	if GameState.has_save():
		var cont := Button.new()
		cont.text = "Continue saved game"
		cont.custom_minimum_size = Vector2(300, 48)
		cont.pressed.connect(_on_continue)
		panel.add_child(cont)


func _swatch_row(label_text: String, hexes: Array, on_pick: Callable) -> Control:
	var box := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	box.add_child(label)
	var row := HBoxContainer.new()
	box.add_child(row)
	for hex in hexes:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(44, 44)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(hex)
		style.set_border_width_all(2)
		style.border_color = Color.WHITE
		for state in ["normal", "hover", "pressed", "focus"]:
			swatch.add_theme_stylebox_override(state, style)
		swatch.pressed.connect(on_pick.bind(Color(hex)))
		row.add_child(swatch)
	return box


func _set_skin(color: Color) -> void:
	GameState.skin_color = color
	avatar.queue_redraw()


func _set_hair(color: Color) -> void:
	GameState.hair_color = color
	avatar.queue_redraw()


func _set_shirt(color: Color) -> void:
	GameState.shirt_color = color
	avatar.queue_redraw()


func _on_continue() -> void:
	if GameState.load_game():
		get_tree().change_scene_to_file("res://farm.tscn")


func _on_start() -> void:
	var chosen := name_edit.text.strip_edges()
	GameState.player_name = chosen if chosen != "" else "Hero"
	GameState.start_new_game()
	get_tree().change_scene_to_file("res://farm.tscn")
