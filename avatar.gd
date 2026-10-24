extends Node2D
# 16x16 pixel hero in the same style as the Kenney tiles. Origin is at the feet.
# O outline, S skin, H hair, T shirt, P pants, E eyes.
# The hero is painted into a tiny image and drawn through SmoothTexture, like all the other art.

const GRID := [
	"................",
	".....OOOOOO.....",
	"....OHHHHHHO....",
	"...OHHHHHHHHO...",
	"...OHHHHHHHHO...",
	"...OHSSSSSSHO...",
	"...OSESSSSESO...",
	"...OSSSSSSSSO...",
	"....OSSSSSSO....",
	".....OOOOOO.....",
	"....OTTTTTTO....",
	"...OTTTTTTTTO...",
	"...OSTTTTTTSO...",
	"....OPPPPPPO....",
	"....OPPOOPPO....",
	".....OO..OO.....",
]

const OUTLINE := Color("2e2233")
const PANTS := Color("3b4a7a")
const STEP_TIME := 0.16
const Outfits := preload("res://outfits.gd")
const SmoothTexture := preload("res://smooth_texture.gd")
const IMG_W := 24
const IMG_H := 28
const ORIGIN := Vector2i(12, 22) # where the feet sit in the image

static var _cache := {}

# Set by the player each frame; the sprite only redraws when something visible changes.
var walking := false
var facing_up := false
var _step := 0
var _step_timer := 0.0
var _spark_time := 0.0


func _ready() -> void:
	GameState.equipment_changed.connect(queue_redraw)


func set_motion(is_walking: bool, up: bool) -> void:
	if up != facing_up:
		facing_up = up
		queue_redraw()
	if is_walking != walking:
		walking = is_walking
		_step = 0
		_step_timer = 0.0
		queue_redraw()


func _process(delta: float) -> void:
	if GameState.hat == "slime_crown":
		_spark_time += delta
		if _spark_time >= 0.2:
			_spark_time = 0.0
			queue_redraw()
	if not walking:
		return
	_step_timer += delta
	if _step_timer >= STEP_TIME:
		_step_timer -= STEP_TIME
		_step = (_step + 1) % 4
		queue_redraw()


func _draw() -> void:
	var spark := int(Time.get_ticks_msec() / 200) % 6 if GameState.hat == "slime_crown" else -1
	var key := "%s|%s|%s|%s|%s|%s|%d|%s|%d" % [
		GameState.skin_color.to_html(false), GameState.hair_color.to_html(false), GameState.shirt_color.to_html(false),
		GameState.armor, GameState.hat, facing_up, _step if walking else -1, walking, spark]
	if not _cache.has(key):
		if _cache.size() > 120:
			_cache.clear()
		_cache[key] = SmoothTexture.from_image(_render(spark))
	draw_texture(_cache[key], Vector2(-ORIGIN.x, -ORIGIN.y))


func _put(img: Image, x: int, y: int, c: Color) -> void:
	var px := x + ORIGIN.x
	var py := y + ORIGIN.y
	if px < 0 or py < 0 or px >= IMG_W or py >= IMG_H:
		return
	if c.a < 1.0:
		var below := img.get_pixel(px, py)
		c = below.blend(c) if below.a > 0.0 else c
	img.set_pixel(px, py, c)


func _render(spark: int) -> Image:
	var img := Image.create_empty(IMG_W, IMG_H, false, Image.FORMAT_RGBA8)
	var palette := {
		"O": OUTLINE,
		"E": OUTLINE,
		"S": GameState.skin_color,
		"H": GameState.hair_color,
		"T": GameState.shirt_color,
		"P": PANTS,
	}
	var armored := GameState.armor != ""
	if armored:
		var gear: Dictionary = Outfits.ARMOR[GameState.armor]
		palette["T"] = gear.torso
		palette["P"] = gear.legs
		palette["R"] = gear.trim
	# Step cycle: 0 stand, 1 left foot forward, 2 stand, 3 right foot forward. Body bobs on 1 and 3.
	var bob := -1 if walking and _step % 2 == 1 else 0
	for y in GRID.size():
		var row: String = GRID[y]
		for x in row.length():
			var key := row[x]
			if key == ".":
				continue
			# Back view: no face, hair covers the head.
			if facing_up and (key == "S" or key == "E") and y <= 8:
				key = "H"
			# Armor trim: shoulders and gloves.
			if armored and ((y == 11 and (x == 4 or x == 11)) or (y == 12 and key == "S")):
				key = "R"
			var xx := x
			if y >= 14 and walking and _step % 2 == 1:
				# Shift the feet to fake a stride, alternating sides.
				xx += -1 if (x < 8) == (_step == 1) else 1
				xx = clampi(xx, 4, 11)
			_put(img, xx - 8, y - 16 + (bob if y < 14 else 0), palette[key])
	_draw_hat(img, bob, spark)
	return img


func _draw_hat(img: Image, bob: int, spark: int) -> void:
	if GameState.hat == "":
		return
	var h: Dictionary = Outfits.HATS[GameState.hat]
	var rows: Array = h.rows
	for i in rows.size():
		var row: String = rows[i]
		for x in row.length():
			var c := row[x]
			if c == ".":
				continue
			var col: Color = OUTLINE if c == "O" else (h.a if c == "A" else h.b)
			_put(img, x - 8, h.y0 + i - 16 + bob, col)
	if spark >= 0:
		# Twinkling sparkles around the crown.
		var spots := [Vector2i(3, -4), Vector2i(12, -3), Vector2i(1, 1), Vector2i(14, 0), Vector2i(8, -6), Vector2i(5, -2)]
		for i in 2:
			var p: Vector2i = spots[(spark + i * 3) % spots.size()]
			_put(img, p.x - 8, p.y - 16 + bob, Color("fff6d0"))
			_put(img, p.x - 9, p.y - 16 + bob, Color("fff6d0", 0.5))
			_put(img, p.x - 7, p.y - 16 + bob, Color("fff6d0", 0.5))
			_put(img, p.x - 8, p.y - 17 + bob, Color("fff6d0", 0.5))
			_put(img, p.x - 8, p.y - 15 + bob, Color("fff6d0", 0.5))
