extends Sprite2D
# A soft, blurry shadow that lies on the ground under things. Tall objects (trees, houses) cast
# longer shadows that swing from west to east as the day goes by; small ones just fade at night.
# The area calls update_sun() on every shadow a few times a second.

const PixelArt := preload("res://pixel_art.gd")

var size := Vector2(16, 6) # footprint in px
var tall := 0.0 # 0 for flat shadows (people, benches); about 1 for trees
var home := Vector2.ZERO # offset from the parent's origin


static func attach(parent: Node, footprint: Vector2, offset := Vector2.ZERO, height := 0.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.set_script(load("res://soft_shadow.gd"))
	s.size = footprint
	s.home = offset
	s.tall = height
	parent.add_child(s)
	return s


func _ready() -> void:
	texture = PixelArt.soft_shadow()
	centered = true
	z_as_relative = false
	z_index = -4
	add_to_group("soft_shadows")
	update_sun(0.0, 1.0, 0.5)


# sun_x: -1 (shadows lean left, morning) to +1 (right, evening). length: 1 at noon, longer at dawn/dusk.
func update_sun(sun_x: float, length: float, strength: float) -> void:
	modulate = Color(1, 1, 1, strength)
	var stretch := 1.0 + tall * (length - 0.6) * 0.8
	scale = Vector2(size.x * stretch, size.y) / 64.0
	position = home + Vector2(sun_x * size.x * 0.4 * tall * length, 0.0)
