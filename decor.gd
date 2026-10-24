extends Node2D
# Small bits of scenery. Set `kind` before adding to the tree:
#   lamp (lights up at night), torch (always lit, flickers), bench, flowers (a planter w px wide), fence (w x h px rectangle with
#   a gap in the top edge), critter (a dungeon-sheet sprite that hops about).
# Origin is the bottom-centre, except flowers and fence where it is the top-left corner.

const Tiles := preload("res://tiles.gd")
const PixelArt := preload("res://pixel_art.gd")
const SoftShadow := preload("res://soft_shadow.gd")
const DUNGEON := preload("res://assets/dungeon/tiles.png")

var kind := "lamp"
var w := 32.0
var h := 16.0
var gap := Vector2.ZERO # fence: x range of the opening along the top edge, in px from the left
var tile := 120
var light_color := Color(1.0, 0.62, 0.25)

var _t := randf() * 10.0
var _light: PointLight2D
var _check := 0.0


func _ready() -> void:
	set_process(false)
	match kind:
		"lamp":
			SoftShadow.attach(self, Vector2(14, 5), Vector2(0, -1), 0.5)
			var s := Sprite2D.new()
			s.texture = PixelArt.lamp()
			s.centered = false
			s.position = Vector2(-8, -33)
			add_child(s)
			_light = PointLight2D.new()
			_light.texture = PixelArt.light()
			_light.texture_scale = 0.9
			_light.color = Color(1.0, 0.8, 0.45)
			_light.position = Vector2(0, -25)
			_light.visible = false
			add_child(_light)
			set_process(true)
		"torch":
			var s := Sprite2D.new()
			s.name = "Flame"
			s.texture = PixelArt.torch(0)
			s.centered = false
			add_child(s)
			_light = PointLight2D.new()
			_light.texture = PixelArt.light()
			_light.texture_scale = 1.1
			_light.color = light_color
			_light.energy = 0.9
			_light.position = Vector2(4, 5)
			add_child(_light)
			set_process(true)
		"bench":
			SoftShadow.attach(self, Vector2(28, 7), Vector2(0, -1), 0.3)
			var s := Sprite2D.new()
			s.texture = PixelArt.bench()
			s.centered = false
			s.position = Vector2(-12, -16)
			add_child(s)
		"flowers":
			z_index = -6
			var s := Sprite2D.new()
			s.texture = PixelArt.flower_bed(maxi(roundi(w / 16.0), 1), int(position.x * 31 + position.y))
			s.centered = false
			add_child(s)
		"critter":
			var s := Tiles.sprite(DUNGEON, tile, Vector2(-8, -15))
			s.name = "Sprite"
			add_child(s)
			set_process(true)
		"fence":
			queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if kind == "critter":
		var s := get_node("Sprite") as Sprite2D
		s.position.y = -15.0 - absf(sin(_t * 3.0)) * 2.0
		s.flip_h = sin(_t * 0.7) > 0.0
	elif kind == "torch":
		_check -= delta
		if _check <= 0.0:
			_check = randf_range(0.1, 0.2)
			(get_node("Flame") as Sprite2D).texture = PixelArt.torch(randi() % 2)
			_light.energy = randf_range(0.8, 1.0)
	elif kind == "lamp":
		_check -= delta
		if _check <= 0.0:
			_check = 0.25
			_update_light()
		if _light.visible:
			_light.energy = _target_energy() + sin(_t * 5.0) * 0.03


func _target_energy() -> float:
	var sun := sin((GameState.time_of_day - 0.25) * TAU)
	var darkness := 1.0 - clampf(sun * 0.5 + 0.6, 0.0, 1.0)
	return clampf(darkness * 1.5, 0.0, 1.0)


func _update_light() -> void:
	_light.visible = _target_energy() > 0.05


func _draw() -> void:
	if kind != "fence":
		return
	var post := Color("5a3b1e")
	var post_light := Color("8a5a2b")
	var rail := Color("8a5a2b")
	var edge := Color("2e2233")
	for e in [[Vector2(0, 0), Vector2(w, 0), true], [Vector2(0, h), Vector2(w, h), false], [Vector2(0, 0), Vector2(0, h), false], [Vector2(w, 0), Vector2(w, h), false]]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var is_top: bool = e[2]
		var horizontal := a.y == b.y
		# Rails first, so the posts stand in front of them.
		var spans: Array = [[a, b]]
		if is_top and gap != Vector2.ZERO:
			spans = [[a, Vector2(gap.x, a.y)], [Vector2(gap.y, a.y), b]]
		for s in spans:
			var p: Vector2 = s[0]
			var q: Vector2 = s[1]
			if horizontal:
				draw_rect(Rect2(p.x, p.y - 6, q.x - p.x, 3), edge)
				draw_rect(Rect2(p.x, p.y - 5, q.x - p.x, 1), post_light)
			else:
				draw_rect(Rect2(p.x - 1, p.y, 3, q.y - p.y), edge)
				draw_rect(Rect2(p.x, p.y, 1, q.y - p.y), rail)
		var n := int(a.distance_to(b) / 12.0)
		for i in range(n + 1):
			var p := a.lerp(b, float(i) / maxf(n, 1))
			if is_top and p.x > gap.x - 2.0 and p.x < gap.y + 2.0 and gap != Vector2.ZERO and i > 0 and i < n:
				continue
			draw_rect(Rect2(p.x - 2, p.y - 9, 4, 11), edge)
			draw_rect(Rect2(p.x - 1, p.y - 8, 2, 9), post)
			draw_rect(Rect2(p.x - 1, p.y - 8, 1, 9), post_light)
