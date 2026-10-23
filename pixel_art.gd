extends RefCounted
# Procedural pixel art in the same style as the Kenney tiles: a 1px dark outline, a small fixed
# palette, and two or three tones per surface. Textures are built once and cached.

const OUT := Color("2e2233")
const STONE_L := Color("d4dae4")
const STONE_M := Color("a9b3c4")
const STONE_D := Color("7b8598")
const WATER_D := Color("2f6fb0")
const WATER := Color("3b82c4")
const WATER_L := Color("7cc0f0")
const FOAM := Color("e8f6ff")
const WOOD_L := Color("b07a3c")
const WOOD_M := Color("8a5a2b")
const WOOD_D := Color("5a3b1e")
const SOIL := Color("5e3e22")
const SOIL_L := Color("7a5230")
const SOIL_D := Color("4a2f18")
const LEAF := Color("3e8a3a")
const LEAF_L := Color("5fb04e")
const IRON := Color("3a3550")
const IRON_L := Color("5d5880")
const GLASS_D := Color("f2c14e")
const GLASS := Color("ffe08a")
const GLASS_L := Color("fff6d0")
const BLOOMS := [Color("ff6b8b"), Color("f2c14e"), Color("b86bff"), Color("f5f5f5"), Color("ff9f43"), Color("6ba8ff")]

const FOUNTAIN_FRAMES := 6

static var _cache := {}


# ---------- drawing helpers ----------

static func canvas(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func put(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a < 1.0:
		var below := img.get_pixel(x, y)
		c = below.blend(c) if below.a > 0.0 else c
	img.set_pixel(x, y, c)


static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in h:
		for xx in w:
			put(img, x + xx, y + yy, c)


static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(floori(cy - ry) - 1, ceili(cy + ry) + 2):
		for x in range(floori(cx - rx) - 1, ceili(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				put(img, x, y, c)


static func tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


# ---------- fountain ----------
# Origin (the point that should sit on the fountain's centre) is returned by fountain_origin().

const F_W := 64
const F_H := 76
const F_CX := 32
const F_CY := 52
const F_RX := 27
const F_RY := 17


static func fountain_origin() -> Vector2:
	return Vector2(F_CX, F_CY)


static func fountain_frames() -> Array:
	if _cache.has("fountain"):
		return _cache["fountain"]
	var frames: Array = []
	for f in FOUNTAIN_FRAMES:
		frames.append(tex(_fountain_image(f)))
	_cache["fountain"] = frames
	return frames


static func _fountain_image(f: int) -> Image:
	var img := canvas(F_W, F_H)
	var cx := F_CX
	var cy := F_CY
	var rx := F_RX
	var ry := F_RY
	ellipse(img, cx + 1, cy + 5, rx + 1, ry, Color(0, 0, 0, 0.28))
	# Stone rim: dark bottom edge, mid body, light top, like a bevel.
	ellipse(img, cx, cy, rx, ry, OUT)
	ellipse(img, cx, cy, rx - 1, ry - 1, STONE_D)
	ellipse(img, cx, cy - 1, rx - 1, ry - 2, STONE_M)
	ellipse(img, cx, cy - 2, rx - 3, ry - 4, STONE_L)
	# Seams between the rim stones.
	for k in 20:
		var a := TAU * k / 20.0
		for r in [3.2, 4.4]:
			put(img, roundi(cx + (rx - r) * cos(a)), roundi(cy - 1 + (ry - r) * sin(a)), STONE_M if r == 3.2 else STONE_D)
	# Inner wall and water.
	ellipse(img, cx, cy + 1, rx - 7, ry - 6, OUT)
	ellipse(img, cx, cy + 1, rx - 8, ry - 7, STONE_D)
	ellipse(img, cx, cy + 3, rx - 9, ry - 9, WATER)
	ellipse(img, cx, cy + 5, rx - 12, ry - 12, WATER_D)
	# Ripples that drift outward over the six frames.
	for ring in 3:
		var rr := 0.3 + 0.25 * ring + (f % 3) * 0.03
		for k in 24:
			if (k + f + ring) % 4 == 0:
				var a := TAU * k / 24.0
				put(img, roundi(cx + (rx - 10) * rr * cos(a)), roundi(cy + 4 + (ry - 11) * rr * sin(a)), WATER_L)
	# Central pillar.
	ellipse(img, cx, cy + 2, 9, 4, OUT)
	ellipse(img, cx, cy + 1, 8, 3, STONE_M)
	rect(img, cx - 4, cy - 26, 9, 28, OUT)
	rect(img, cx - 3, cy - 26, 7, 27, STONE_M)
	rect(img, cx - 3, cy - 26, 2, 27, STONE_L)
	rect(img, cx + 2, cy - 26, 2, 27, STONE_D)
	for y in range(cy - 22, cy, 6):
		rect(img, cx - 3, y, 7, 1, STONE_D)
	# Upper bowl.
	ellipse(img, cx, cy - 27, 12, 5, OUT)
	ellipse(img, cx, cy - 27, 11, 4, STONE_D)
	ellipse(img, cx, cy - 28, 11, 4, STONE_M)
	ellipse(img, cx, cy - 28, 9, 3, WATER)
	ellipse(img, cx, cy - 27, 6, 1, WATER_L)
	# Water jets: droplets leave the bowl, arc outward and fall back into the basin.
	var y0 := cy - 30
	var dirs: Array[float] = [-1.0, -0.72, -0.45, -0.18, 0.18, 0.45, 0.72, 1.0]
	for i in dirs.size():
		for n in 3:
			var u := fposmod((f / float(FOUNTAIN_FRAMES)) + i * 0.06 + n / 3.0, 1.0)
			var x: float = cx + dirs[i] * u * 20.0
			var y: float = y0 + (cy - 4 - y0) * u - 17.0 * 4.0 * u * (1.0 - u)
			var col := FOAM if (i + n) % 2 == 0 else WATER_L
			put(img, roundi(x), roundi(y), col)
			if absf(dirs[i]) < 0.5 and u > 0.25 and u < 0.75:
				put(img, roundi(x), roundi(y) + 1, WATER_L)
	for k in 7 + (f % 3) * 2:
		put(img, cx, y0 - k, FOAM if k % 2 == 0 else WATER_L)
	put(img, cx - 1, y0 - 3, WATER_L)
	put(img, cx + 1, y0 - 3, WATER_L)
	return img


# ---------- lamp post ----------
# Origin is the bottom-centre of the base. The lantern glass is at (8, 8) in the image.

const L_W := 16
const L_H := 34


static func lamp() -> Texture2D:
	if _cache.has("lamp"):
		return _cache["lamp"]
	var img := canvas(L_W, L_H)
	ellipse(img, 8, 32, 6, 2, Color(0, 0, 0, 0.28))
	# Base and post.
	rect(img, 4, 28, 8, 5, OUT)
	rect(img, 5, 29, 6, 3, IRON)
	rect(img, 5, 29, 6, 1, IRON_L)
	rect(img, 6, 11, 4, 18, OUT)
	rect(img, 7, 11, 2, 18, IRON)
	rect(img, 7, 11, 1, 18, IRON_L)
	# Lantern: glass halves split by an iron bar, with a pointed cap.
	rect(img, 3, 3, 10, 10, OUT)
	rect(img, 4, 4, 8, 8, GLASS_D)
	rect(img, 5, 5, 6, 6, GLASS)
	rect(img, 6, 6, 4, 4, GLASS_L)
	rect(img, 7, 4, 2, 8, IRON)
	rect(img, 4, 12, 8, 1, IRON)
	rect(img, 4, 2, 8, 1, OUT)
	rect(img, 5, 1, 6, 1, OUT)
	rect(img, 7, 0, 2, 1, OUT)
	rect(img, 5, 2, 6, 1, IRON)
	rect(img, 6, 1, 4, 1, IRON_L)
	_cache["lamp"] = tex(img)
	return _cache["lamp"]


# A soft round light for lamps, as a white-to-black radial gradient.
static func light() -> Texture2D:
	if _cache.has("light"):
		return _cache["light"]
	var g := Gradient.new()
	g.colors = PackedColorArray([Color.WHITE, Color(0.35, 0.35, 0.35), Color.BLACK])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 128
	t.height = 128
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	_cache["light"] = t
	return t


# ---------- bench ----------
# Origin is the bottom-centre.

static func bench() -> Texture2D:
	if _cache.has("bench"):
		return _cache["bench"]
	var img := canvas(24, 18)
	ellipse(img, 12, 16, 11, 2, Color(0, 0, 0, 0.28))
	# Legs.
	rect(img, 3, 11, 4, 6, OUT)
	rect(img, 4, 12, 2, 4, WOOD_D)
	rect(img, 17, 11, 4, 6, OUT)
	rect(img, 18, 12, 2, 4, WOOD_D)
	# Back rest: two slats between two posts.
	rect(img, 2, 0, 20, 8, OUT)
	rect(img, 3, 1, 18, 2, WOOD_L)
	rect(img, 3, 3, 18, 1, WOOD_M)
	rect(img, 3, 5, 18, 1, WOOD_M)
	rect(img, 3, 6, 18, 1, WOOD_D)
	rect(img, 3, 4, 18, 1, OUT)
	# Seat.
	rect(img, 1, 8, 22, 6, OUT)
	rect(img, 2, 9, 20, 2, WOOD_L)
	rect(img, 2, 11, 20, 1, WOOD_M)
	rect(img, 2, 12, 20, 1, WOOD_D)
	_cache["bench"] = tex(img)
	return _cache["bench"]


# ---------- flower bed ----------
# A wooden planter, `tiles` wide and one tile tall. Origin is the top-left corner.

static func flower_bed(tiles: int, seed_value: int) -> Texture2D:
	var key := "bed_%d_%d" % [tiles, seed_value]
	if _cache.has(key):
		return _cache[key]
	var w := tiles * 16
	var img := canvas(w, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# Wooden frame with rounded corners.
	rect(img, 0, 0, w, 16, OUT)
	for p in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, 15), Vector2i(w - 1, 15)]:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	rect(img, 1, 1, w - 2, 14, WOOD_M)
	rect(img, 1, 1, w - 2, 1, WOOD_L)
	rect(img, 1, 14, w - 2, 1, WOOD_D)
	# Soil with a little texture.
	rect(img, 3, 3, w - 6, 10, SOIL)
	for i in int(w * 0.6):
		put(img, rng.randi_range(3, w - 4), rng.randi_range(3, 12), SOIL_L if rng.randf() < 0.5 else SOIL_D)
	# Two staggered rows of flowers.
	for row in 2:
		var x := 5 + row * 3
		while x < w - 4:
			_flower(img, x + rng.randi_range(-1, 1), 5 + row * 3, rng)
			x += 6
	_cache[key] = tex(img)
	return _cache[key]


static func _flower(img: Image, x: int, y: int, rng: RandomNumberGenerator) -> void:
	var bloom: Color = BLOOMS[rng.randi() % BLOOMS.size()]
	# Stem and a leaf.
	for yy in range(y + 2, 13):
		put(img, x, yy, LEAF)
	put(img, x + 1, y + 3, LEAF_L)
	put(img, x - 1, y + 4, LEAF_L)
	match rng.randi() % 3:
		0: # daisy
			for o in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
				put(img, x + o.x, y + o.y, bloom)
			put(img, x, y, GLASS_D if bloom != GLASS_D else FOAM)
		1: # tulip
			for o in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]:
				put(img, x + o.x, y + o.y, bloom)
			put(img, x, y - 1, bloom.lightened(0.35))
		_: # bud
			rect(img, x, y, 2, 2, bloom)
			put(img, x, y, bloom.lightened(0.35))
