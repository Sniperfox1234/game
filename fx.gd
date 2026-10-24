extends RefCounted
# Screen-wide finishing for an area: a post-processing layer (vignette, tilt-shift, colour grading),
# optional sun shafts, and a bloom environment so bright lights glow.

static func attach(area: Node, profile: Dictionary) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 1
	layer.name = "PostFX"
	area.add_child(layer)

	if profile.get("shafts", 0.0) > 0.0:
		var shafts := ColorRect.new()
		shafts.set_anchors_preset(Control.PRESET_FULL_RECT)
		shafts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/shafts.gdshader")
		sm.set_shader_parameter("strength", profile.shafts)
		shafts.material = sm
		shafts.name = "Shafts"
		layer.add_child(shafts)

	var post := ColorRect.new()
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := ShaderMaterial.new()
	pm.shader = load("res://shaders/post.gdshader")
	pm.set_shader_parameter("vignette", profile.get("vignette", 0.30))
	pm.set_shader_parameter("blur", profile.get("blur", 1.1))
	pm.set_shader_parameter("saturation", profile.get("saturation", 1.10))
	pm.set_shader_parameter("contrast", profile.get("contrast", 1.05))
	post.material = pm
	post.name = "Post"
	layer.add_child(post)

	if profile.get("glow", true):
		var env := Environment.new()
		env.background_mode = Environment.BG_CANVAS
		env.glow_enabled = true
		env.glow_intensity = profile.get("glow_intensity", 0.55)
		env.glow_strength = 1.0
		env.glow_bloom = 0.06
		env.glow_hdr_threshold = 0.95
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		var we := WorldEnvironment.new()
		we.environment = env
		area.add_child(we)
	return layer


# The sun's effect on shadows for a time of day (0..1, where 0.25 is 6am): [sun_x, length, strength].
static func sun(time_of_day: float) -> Array:
	var ang := clampf((time_of_day - 0.25) / 0.5, 0.0, 1.0) * PI
	var day := sin(ang)
	var length := clampf(1.0 / maxf(day, 0.3), 1.0, 2.6)
	var strength := 0.10 + 0.42 * clampf(day * 1.6, 0.0, 1.0)
	return [-cos(ang), length, strength]
