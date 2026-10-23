extends Node2D
# Small bits of scenery drawn from shapes. Set `kind` before adding to the tree:
#   lamp, bench, flowers (w x h px bed), fence (w x h px rectangle with a gap), critter (tile).
# Origin is the bottom-centre, except flowers and fence where it is the top-left corner.

const Tiles := preload("res://tiles.gd")
const DUNGEON := preload("res://assets/dungeon/tiles.png")

var kind := "lamp"
var w := 32.0
var h := 16.0
var gap := Vector2.ZERO # fence: x range of the opening along the top edge, in px from the left
var tile := 120
var _t := randf() * 10.0
var _dots: Array = []


func _ready() -> void:
	if kind == "flowers":
		z_index = -6
		var rng := RandomNumberGenerator.new()
		rng.seed = int(position.x * 31 + position.y)
		var colors := [Color("ff6b8b"), Color("f2c14e"), Color("b86bff"), Color("ffffff"), Color("ff9f43")]
		for i in int(w * h / 22.0):
			_dots.append([Vector2(rng.randf_range(3, w - 3), rng.randf_range(3, h - 3)), colors[rng.randi() % colors.size()]])
	elif kind == "critter":
		var s := Tiles.sprite(DUNGEON, tile, Vector2(-8, -15))
		s.name = "Sprite"
		add_child(s)
	if kind == "critter" or kind == "lamp":
		set_process(true)
	else:
		set_process(false)


func _process(delta: float) -> void:
	_t += delta
	if kind == "critter":
		var s := get_node("Sprite") as Sprite2D
		s.position.y = -15.0 - absf(sin(_t * 3.0)) * 2.0
		s.flip_h = sin(_t * 0.7) > 0.0
	else:
		queue_redraw()


func _draw() -> void:
	match kind:
		"lamp":
			draw_rect(Rect2(-4, -1, 8, 2), Color(0, 0, 0, 0.25))
			draw_rect(Rect2(-1.5, -22, 3, 21), Color("2e2233"))
			draw_rect(Rect2(-4, -28, 8, 7), Color("2e2233"))
			draw_rect(Rect2(-3, -27, 6, 5), Color("ffe9a0"))
			var glow := 0.18 + 0.05 * sin(_t * 3.0)
			draw_circle(Vector2(0, -24), 11.0, Color(1.0, 0.9, 0.5, glow))
		"bench":
			draw_rect(Rect2(-12, -1, 24, 2), Color(0, 0, 0, 0.25))
			draw_rect(Rect2(-11, -7, 3, 7), Color("4a2f1a"))
			draw_rect(Rect2(8, -7, 3, 7), Color("4a2f1a"))
			draw_rect(Rect2(-12, -10, 24, 4), Color("8a5a2b"))
			draw_rect(Rect2(-12, -10, 24, 1), Color("a8743b"))
			draw_rect(Rect2(-12, -15, 24, 3), Color("6b4423"))
		"flowers":
			draw_rect(Rect2(0, 0, w, h), Color("5a3b1e"))
			draw_rect(Rect2(1, 1, w - 2, h - 2), Color("6e4a28"))
			for d in _dots:
				var p: Vector2 = d[0]
				draw_rect(Rect2(p.x, p.y + 1, 1, 2), Color("3e8a3a"))
				draw_circle(p, 1.6, d[1])
		"fence":
			var post := Color("6b4423")
			var rail := Color("8a5a2b")
			for edge in [[Vector2(0, 0), Vector2(w, 0), true], [Vector2(0, h), Vector2(w, h), false], [Vector2(0, 0), Vector2(0, h), false], [Vector2(w, 0), Vector2(w, h), false]]:
				var a: Vector2 = edge[0]
				var b: Vector2 = edge[1]
				var n := int(a.distance_to(b) / 12.0)
				for i in range(n + 1):
					var p := a.lerp(b, float(i) / maxf(n, 1))
					if edge[2] and p.x > gap.x and p.x < gap.y:
						continue
					draw_rect(Rect2(p.x - 1, p.y - 7, 3, 9), post)
				if edge[2] and gap != Vector2.ZERO:
					draw_rect(Rect2(a.x, a.y - 5, gap.x - a.x, 2), rail)
					draw_rect(Rect2(gap.y, a.y - 5, b.x - gap.y, 2), rail)
				else:
					var horizontal: bool = a.y == b.y
					if horizontal:
						draw_rect(Rect2(a.x, a.y - 5, b.x - a.x, 2), rail)
					else:
						draw_rect(Rect2(a.x - 1, a.y - 5, 2, b.y - a.y), rail)
		"critter":
			draw_rect(Rect2(-5, -1, 10, 2), Color(0, 0, 0, 0.25))
