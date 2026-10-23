extends RefCounted
# Shared look for pop-ups: rounded dark panels with a gold border and soft shadow.

const BG := Color("1d1b2e")
const BORDER := Color("e8c872")
const CREAM := Color("f4ecd8")
const MUTED := Color("8a86a6")


static func panel(radius := 16, bg := BG, border_w := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg, 0.96)
	s.border_color = BORDER
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	s.anti_aliasing = true
	return s


# A small rounded pill, used for the speaker's name tag and the toast.
static func pill(bg: Color, border: Color = BORDER, border_w := 2) -> StyleBoxFlat:
	var s := panel(18, bg, border_w)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	s.shadow_size = 5
	s.border_color = border
	return s


static func button(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.anti_aliasing = true
	return s


# Theme for shop-style menus: rounded panel, rounded buttons, cream text.
static func menu_theme() -> Theme:
	var t := Theme.new()
	t.set_stylebox("panel", "PanelContainer", panel())
	t.set_stylebox("normal", "Button", button(Color("2e2b47"), Color("4a4670")))
	t.set_stylebox("hover", "Button", button(Color("3d3a5e"), BORDER))
	t.set_stylebox("pressed", "Button", button(Color("55507f"), BORDER))
	t.set_stylebox("disabled", "Button", button(Color("24223a"), Color("33304a")))
	var focus := button(Color(0, 0, 0, 0), BORDER)
	focus.draw_center = false
	focus.set_border_width_all(3)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_color("font_color", "Label", CREAM)
	return t
