extends PanelContainer
# A reusable rounded menu: a gold title, some text lines and buttons. The owner clears and
# refills it whenever something changes. Used by the builder and the pet shop.

const UiStyle := preload("res://ui_style.gd")

var box := VBoxContainer.new()
var title_label := Label.new()


func _ready() -> void:
	theme = UiStyle.menu_theme()
	box.add_theme_constant_override("separation", 8)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", UiStyle.BORDER)
	box.add_child(title_label)
	add_child(box)
	custom_minimum_size = Vector2(520, 0)
	position = Vector2(316, 120)
	visible = false


func setup(title: String) -> void:
	title_label.text = title


# Removes everything except the title.
func clear() -> void:
	for c in box.get_children():
		if c != title_label:
			box.remove_child(c)
			c.queue_free()


func add_label(text: String, color: Color = UiStyle.CREAM, size := 17) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(470, 0)
	box.add_child(l)
	return l


func add_button(text: String, action: Callable, disabled := false) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.pressed.connect(action)
	box.add_child(b)
	return b


func buttons() -> Array[Button]:
	var out: Array[Button] = []
	for c in box.get_children():
		if c is Button:
			out.append(c)
	return out


# Focuses the button at `index` (or the nearest enabled one) so keyboard play works.
func focus_button(index := 0) -> void:
	var list := buttons()
	if list.is_empty():
		return
	index = clampi(index, 0, list.size() - 1)
	for i in range(index, list.size()):
		if not list[i].disabled:
			list[i].grab_focus()
			return
	for i in range(index - 1, -1, -1):
		if not list[i].disabled:
			list[i].grab_focus()
			return


func focused_index() -> int:
	var list := buttons()
	for i in list.size():
		if list[i].has_focus():
			return i
	return 0
