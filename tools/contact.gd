extends Node2D
# Dev tool: renders a tile sheet with index numbers, saves a PNG, quits.
# Run: Godot --path . res://tools/contact.tscn -- <sheet.png> <out.png>

const SCALE := 4


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var tex: Texture2D = load(args[0])
	var out_path: String = args[1]
	var cols := 12
	var rows := 11
	var bg := ColorRect.new()
	bg.color = Color("ff00ff")
	bg.size = Vector2(cols * 16 * SCALE, rows * 16 * SCALE) * 1.0
	add_child(bg)
	for i in cols * rows:
		var x := (i % cols) * 16
		var y := (i / cols) * 16
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.region_enabled = true
		spr.region_rect = Rect2(x, y, 16, 16)
		spr.centered = false
		spr.position = Vector2(x, y) * SCALE
		spr.scale = Vector2(SCALE, SCALE)
		add_child(spr)
		var lbl := Label.new()
		lbl.text = str(i)
		lbl.position = Vector2(x, y) * SCALE
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 5)
		add_child(lbl)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_path)
	get_tree().quit()
