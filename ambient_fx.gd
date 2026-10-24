extends Node2D
# Drifting particles around the player that suit the place: leaves and petals by day, fireflies at
# night, dust in caves, snow in the frozen caves, sand in the desert, spores in the swamp, sea
# spray at the harbour. Follows its parent (the player); call set_mode() to change the weather.

const PixelArt := preload("res://pixel_art.gd")

var mode := ""
var parts: CPUParticles2D


func _ready() -> void:
	z_index = 50
	parts = CPUParticles2D.new()
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	parts.emission_rect_extents = Vector2(330, 190)
	parts.texture = PixelArt.soft_dot()
	parts.local_coords = false
	add_child(parts)
	parts.emitting = false


func set_mode(new_mode: String) -> void:
	if new_mode == mode:
		return
	mode = new_mode
	parts.emitting = mode != ""
	if mode == "":
		return
	parts.restart()
	parts.one_shot = false
	parts.explosiveness = 0.0
	parts.randomness = 0.6
	parts.direction = Vector2(0, 1)
	parts.spread = 30.0
	parts.gravity = Vector2.ZERO
	parts.angular_velocity_min = 0.0
	parts.angular_velocity_max = 0.0
	parts.scale_amount_min = 0.5
	parts.scale_amount_max = 1.0
	parts.damping_min = 0.0
	parts.damping_max = 0.0
	parts.orbit_velocity_min = 0.0
	parts.orbit_velocity_max = 0.0
	parts.tangential_accel_min = 0.0
	parts.tangential_accel_max = 0.0
	parts.color = Color.WHITE
	parts.color_ramp = null
	match mode:
		"leaves":
			parts.amount = 14
			parts.lifetime = 9.0
			parts.direction = Vector2(1, 0.7)
			parts.spread = 25.0
			parts.initial_velocity_min = 9.0
			parts.initial_velocity_max = 20.0
			parts.angular_velocity_min = -90.0
			parts.angular_velocity_max = 90.0
			parts.tangential_accel_min = -8.0
			parts.tangential_accel_max = 8.0
			parts.scale_amount_min = 0.9
			parts.scale_amount_max = 1.5
			parts.color = Color(0.72, 0.8, 0.28, 0.85)
		"fireflies":
			parts.amount = 26
			parts.lifetime = 5.0
			parts.direction = Vector2(0, -1)
			parts.spread = 180.0
			parts.initial_velocity_min = 3.0
			parts.initial_velocity_max = 10.0
			parts.scale_amount_min = 1.2
			parts.scale_amount_max = 2.2
			parts.color = Color(1.4, 1.3, 0.55, 0.95)
			parts.color_ramp = _pulse_ramp()
		"dust":
			parts.amount = 20
			parts.lifetime = 8.0
			parts.direction = Vector2(0, -1)
			parts.spread = 180.0
			parts.initial_velocity_min = 2.0
			parts.initial_velocity_max = 6.0
			parts.scale_amount_min = 0.5
			parts.scale_amount_max = 1.1
			parts.color = Color(0.9, 0.82, 0.72, 0.28)
		"snow":
			parts.amount = 70
			parts.lifetime = 7.0
			parts.direction = Vector2(0.25, 1.0)
			parts.spread = 12.0
			parts.initial_velocity_min = 14.0
			parts.initial_velocity_max = 26.0
			parts.scale_amount_min = 0.7
			parts.scale_amount_max = 1.6
			parts.color = Color(1, 1, 1, 0.9)
		"sand":
			parts.amount = 60
			parts.lifetime = 4.0
			parts.direction = Vector2(1, 0.15)
			parts.spread = 10.0
			parts.initial_velocity_min = 50.0
			parts.initial_velocity_max = 90.0
			parts.scale_amount_min = 0.4
			parts.scale_amount_max = 0.9
			parts.color = Color(0.92, 0.8, 0.52, 0.5)
		"spores":
			parts.amount = 30
			parts.lifetime = 7.0
			parts.direction = Vector2(0, -1)
			parts.spread = 180.0
			parts.initial_velocity_min = 3.0
			parts.initial_velocity_max = 9.0
			parts.scale_amount_min = 1.0
			parts.scale_amount_max = 2.0
			parts.color = Color(0.7, 1.4, 0.7, 0.8)
			parts.color_ramp = _pulse_ramp()
		"spray":
			parts.amount = 22
			parts.lifetime = 5.0
			parts.direction = Vector2(1, -0.2)
			parts.spread = 40.0
			parts.initial_velocity_min = 12.0
			parts.initial_velocity_max = 26.0
			parts.scale_amount_min = 0.6
			parts.scale_amount_max = 1.2
			parts.color = Color(0.95, 1.0, 1.0, 0.45)
		"embers":
			parts.amount = 28
			parts.lifetime = 6.0
			parts.direction = Vector2(0, -1)
			parts.spread = 40.0
			parts.initial_velocity_min = 12.0
			parts.initial_velocity_max = 28.0
			parts.scale_amount_min = 0.7
			parts.scale_amount_max = 1.5
			parts.color = Color(1.5, 0.8, 0.35, 0.9)
			parts.color_ramp = _pulse_ramp()


# Fades in and out over a particle's life so it twinkles instead of popping.
func _pulse_ramp() -> Gradient:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.2), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	return g
