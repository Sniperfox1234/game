extends RefCounted
# Procedural pixel art in the same style as the Kenney tiles: a 1px dark outline, a small fixed
# palette, and two or three tones per surface. Textures are built once and cached.

const SmoothTexture := preload("res://smooth_texture.gd")
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
const MEAT := Color("d4605a")
const MEAT_L := Color("f08a7e")
const MEAT_D := Color("a03c3c")
const FAT := Color("f3d7c3")
const BONE := Color("f5f5f5")
const RED := Color("9c2a3a")
const RED_L := Color("c43f52")
const GOLD := Color("e8c872")
const GOLD_D := Color("b08a3a")
const FIRE := Color("ff8a2a")
const FIRE_L := Color("ffd966")
const SLATE_A := Color("4b4b62")
const SLATE_B := Color("565670")
const SLATE_G := Color("33334a")
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


static func tex(img: Image) -> Texture2D:
	return SmoothTexture.from_image(img)


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


# ---------- shop interiors ----------

# A wooden shop counter `tiles` wide: planked front and a light top. Origin is the top-left; 22px tall.
static func counter(tiles: int) -> Texture2D:
	var key := "counter_%d" % tiles
	if _cache.has(key):
		return _cache[key]
	var w := tiles * 16
	var img := canvas(w, 24)
	rect(img, 0, 0, w, 22, OUT)
	rect(img, 1, 1, w - 2, 8, WOOD_L)
	for x in range(3, w - 6, 9):
		rect(img, x, 3, 5, 1, WOOD_M)
		rect(img, x + 4, 6, 4, 1, WOOD_M)
	rect(img, 1, 9, w - 2, 1, WOOD_D)
	rect(img, 1, 10, w - 2, 11, WOOD_M)
	for x in range(8, w - 1, 16):
		rect(img, x, 10, 1, 11, WOOD_D)
	rect(img, 1, 20, w - 2, 1, WOOD_D)
	for p in [Vector2i(0, 0), Vector2i(w - 1, 0)]:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	ellipse(img, w / 2.0, 23, w / 2.0 - 2, 1.5, Color(0, 0, 0, 0.25))
	_cache[key] = tex(img)
	return _cache[key]


# A woven rug with a contrasting border and fringe. Origin is the top-left.
static func rug(tiles_w: int, tiles_h: int, main: Color, trim: Color) -> Texture2D:
	var key := "rug_%d_%d_%s" % [tiles_w, tiles_h, main.to_html()]
	if _cache.has(key):
		return _cache[key]
	var w := tiles_w * 16
	var h := tiles_h * 16
	var img := canvas(w, h)
	rect(img, 2, 0, w - 4, h, OUT)
	rect(img, 3, 1, w - 6, h - 2, trim)
	rect(img, 6, 4, w - 12, h - 8, OUT)
	rect(img, 7, 5, w - 14, h - 10, main)
	for x in range(9, w - 9, 6):
		for y in range(7, h - 7, 6):
			put(img, x, y, trim)
			put(img, x + 1, y, trim)
			put(img, x, y + 1, trim)
	for y in range(2, h - 2, 3):
		put(img, 0, y, trim)
		put(img, 1, y, trim)
		put(img, w - 1, y, trim)
		put(img, w - 2, y, trim)
	_cache[key] = tex(img)
	return _cache[key]


# A wall rack hung with a ham, sausage links and a cured leg. Origin is the top-left; 44x34.
static func meat_rack() -> Texture2D:
	if _cache.has("meat_rack"):
		return _cache["meat_rack"]
	var img := canvas(44, 34)
	# Wooden bar and hooks.
	rect(img, 0, 0, 44, 5, OUT)
	rect(img, 1, 1, 42, 3, WOOD_M)
	rect(img, 1, 1, 42, 1, WOOD_L)
	for x in [8, 22, 36]:
		rect(img, x, 5, 1, 3, OUT)
	# Ham: round body, bone at the bottom.
	ellipse(img, 8.5, 17, 7, 9, OUT)
	ellipse(img, 8.5, 17, 6, 8, MEAT)
	ellipse(img, 7.5, 14, 3.5, 4.5, MEAT_L)
	ellipse(img, 9.5, 21, 3, 3, MEAT_D)
	rect(img, 7, 26, 3, 5, OUT)
	rect(img, 8, 26, 1, 4, BONE)
	# Sausage links in a chain.
	for i in 4:
		ellipse(img, 22.5, 11 + i * 6, 4, 3.4, OUT)
		ellipse(img, 22.5, 11 + i * 6, 3, 2.5, MEAT_D)
		put(img, 21, 10 + i * 6, MEAT)
		put(img, 22, 10 + i * 6, MEAT_L)
	# Cured leg with fat cap.
	ellipse(img, 36.5, 15, 5, 8, OUT)
	ellipse(img, 36.5, 15, 4, 7, MEAT_D)
	ellipse(img, 36, 11, 3, 4, FAT)
	ellipse(img, 37, 18, 2, 3, MEAT)
	rect(img, 35, 22, 3, 7, OUT)
	rect(img, 36, 22, 1, 6, BONE)
	_cache["meat_rack"] = tex(img)
	return _cache["meat_rack"]


# A tree-stump chopping block with a cleaver stuck in it. Origin is the bottom-centre; 24x22.
static func chopping_block() -> Texture2D:
	if _cache.has("block"):
		return _cache["block"]
	var img := canvas(24, 22)
	ellipse(img, 12, 20, 10, 2, Color(0, 0, 0, 0.28))
	rect(img, 3, 8, 18, 11, OUT)
	rect(img, 4, 9, 16, 9, WOOD_M)
	rect(img, 4, 9, 3, 9, WOOD_L)
	rect(img, 17, 9, 3, 9, WOOD_D)
	ellipse(img, 12, 8, 9.5, 4.5, OUT)
	ellipse(img, 12, 8, 8.5, 3.5, WOOD_L)
	ellipse(img, 12, 8, 4.5, 1.8, WOOD_M)
	ellipse(img, 12, 8, 1.8, 0.8, WOOD_D)
	# Cleaver: steel blade and wooden handle.
	rect(img, 13, 0, 8, 7, OUT)
	rect(img, 14, 1, 6, 5, STONE_L)
	rect(img, 14, 4, 6, 2, STONE_M)
	rect(img, 20, 3, 4, 2, OUT)
	rect(img, 20, 3, 3, 1, WOOD_M)
	_cache["block"] = tex(img)
	return _cache["block"]


# ---------- armory ----------

# Checkered slate flagstones, `tw` x `th` tiles. Origin is the top-left.
static func slate_floor(tw: int, th: int) -> Texture2D:
	var key := "slate_%d_%d" % [tw, th]
	if _cache.has(key):
		return _cache[key]
	var img := canvas(tw * 16, th * 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for ty in th:
		for tx in tw:
			var base := SLATE_A if (tx + ty) % 2 == 0 else SLATE_B
			rect(img, tx * 16, ty * 16, 16, 16, base)
			rect(img, tx * 16, ty * 16, 16, 1, base.lightened(0.12))
			rect(img, tx * 16, ty * 16, 1, 16, base.lightened(0.08))
			rect(img, tx * 16, ty * 16 + 15, 16, 1, SLATE_G)
			rect(img, tx * 16 + 15, ty * 16, 1, 16, SLATE_G)
			for i in 6:
				put(img, tx * 16 + rng.randi_range(2, 13), ty * 16 + rng.randi_range(2, 13), base.darkened(0.12) if rng.randf() < 0.5 else base.lightened(0.08))
	_cache[key] = tex(img)
	return _cache[key]


# A heraldic banner hanging from a rod, with a swallow-tail bottom. Origin is the top-left; 16x40.
static func banner() -> Texture2D:
	if _cache.has("banner"):
		return _cache["banner"]
	var img := canvas(16, 40)
	rect(img, 0, 0, 16, 4, OUT)
	rect(img, 1, 1, 14, 2, WOOD_M)
	rect(img, 1, 1, 14, 1, WOOD_L)
	rect(img, 2, 4, 12, 34, OUT)
	rect(img, 3, 4, 10, 33, RED)
	rect(img, 3, 4, 2, 33, RED_L)
	rect(img, 3, 4, 10, 1, GOLD)
	rect(img, 3, 4, 1, 33, GOLD_D)
	rect(img, 12, 4, 1, 33, GOLD_D)
	# Shield emblem with a cross.
	rect(img, 5, 10, 6, 9, OUT)
	rect(img, 6, 11, 4, 7, GOLD)
	rect(img, 7, 11, 2, 7, RED)
	rect(img, 6, 13, 4, 2, RED)
	rect(img, 7, 18, 2, 1, OUT)
	# Swallow-tail.
	for y in range(33, 38):
		var cut := (y - 32)
		for x in range(8 - cut, 8 + cut):
			if x >= 3 and x < 13:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	for y in range(33, 38):
		var cut := (y - 32)
		put(img, 8 - cut - 1, y, OUT)
		put(img, 8 + cut, y, OUT)
	_cache["banner"] = tex(img)
	return _cache["banner"]


# A wooden stand wearing a suit of plate armor with a red plume. Origin is the bottom-centre; 22x36.
static func armor_stand() -> Texture2D:
	if _cache.has("armor_stand"):
		return _cache["armor_stand"]
	var img := canvas(22, 36)
	ellipse(img, 11, 34, 9, 2, Color(0, 0, 0, 0.3))
	# Stand: foot and pole.
	rect(img, 4, 31, 14, 4, OUT)
	rect(img, 5, 32, 12, 2, WOOD_M)
	rect(img, 9, 24, 4, 8, OUT)
	rect(img, 10, 25, 2, 7, WOOD_M)
	# Tassets and belt.
	rect(img, 5, 21, 12, 6, OUT)
	rect(img, 6, 22, 10, 4, STONE_M)
	rect(img, 6, 22, 10, 1, WOOD_D)
	rect(img, 10, 22, 2, 1, GOLD)
	for x in [8, 11, 14]:
		put(img, x, 25, STONE_D)
	# Breastplate.
	rect(img, 4, 11, 14, 11, OUT)
	rect(img, 5, 12, 12, 9, STONE_M)
	rect(img, 5, 12, 3, 9, STONE_L)
	rect(img, 14, 12, 3, 9, STONE_D)
	rect(img, 10, 13, 2, 7, STONE_D)
	put(img, 10, 14, GOLD)
	put(img, 11, 14, GOLD)
	# Pauldrons.
	ellipse(img, 3.5, 13.5, 3.5, 3.2, OUT)
	ellipse(img, 3.5, 13.5, 2.5, 2.2, STONE_L)
	ellipse(img, 18.5, 13.5, 3.5, 3.2, OUT)
	ellipse(img, 18.5, 13.5, 2.5, 2.2, STONE_M)
	# Helmet with visor slit and plume.
	ellipse(img, 11, 7, 5.5, 6, OUT)
	ellipse(img, 11, 7, 4.5, 5, STONE_M)
	ellipse(img, 9.5, 5.5, 2, 2.5, STONE_L)
	rect(img, 7, 7, 8, 2, OUT)
	rect(img, 10, 9, 2, 3, OUT)
	rect(img, 10, 0, 3, 3, OUT)
	rect(img, 11, 0, 1, 3, RED_L)
	put(img, 12, 1, RED)
	_cache["armor_stand"] = tex(img)
	return _cache["armor_stand"]


# A wall rack of weapons: two swords, an axe and a spear. Origin is the top-left; 44x30.
static func weapon_rack() -> Texture2D:
	if _cache.has("weapon_rack"):
		return _cache["weapon_rack"]
	var img := canvas(44, 30)
	rect(img, 0, 0, 44, 30, OUT)
	rect(img, 1, 1, 42, 28, WOOD_D)
	rect(img, 1, 1, 42, 2, WOOD_M)
	rect(img, 1, 27, 42, 2, WOOD_M)
	rect(img, 1, 12, 42, 2, WOOD_M)
	# Sword, left.
	rect(img, 6, 3, 5, 24, OUT)
	rect(img, 7, 4, 3, 20, STONE_L)
	rect(img, 9, 4, 1, 20, STONE_M)
	rect(img, 4, 21, 9, 3, OUT)
	rect(img, 5, 22, 7, 1, GOLD)
	rect(img, 7, 24, 3, 3, WOOD_M)
	# Sword, second.
	rect(img, 15, 3, 5, 24, OUT)
	rect(img, 16, 4, 3, 20, STONE_M)
	rect(img, 18, 4, 1, 20, STONE_D)
	rect(img, 13, 21, 9, 3, OUT)
	rect(img, 14, 22, 7, 1, GOLD_D)
	rect(img, 16, 24, 3, 3, WOOD_M)
	# Axe.
	rect(img, 27, 3, 2, 24, OUT)
	rect(img, 27, 4, 1, 23, WOOD_L)
	ellipse(img, 31, 8, 5, 5, OUT)
	ellipse(img, 31, 8, 4, 4, STONE_M)
	ellipse(img, 32, 8, 2.5, 3, STONE_L)
	rect(img, 25, 5, 4, 6, OUT)
	rect(img, 26, 6, 3, 4, STONE_D)
	# Spear.
	rect(img, 38, 6, 2, 21, OUT)
	rect(img, 38, 7, 1, 20, WOOD_L)
	rect(img, 37, 1, 4, 7, OUT)
	rect(img, 38, 2, 2, 5, STONE_L)
	_cache["weapon_rack"] = tex(img)
	return _cache["weapon_rack"]


# A stone forge with a glowing mouth and chimney. Origin is the bottom-centre; 36x34.
static func forge() -> Texture2D:
	if _cache.has("forge"):
		return _cache["forge"]
	var img := canvas(36, 34)
	ellipse(img, 18, 32, 16, 2, Color(0, 0, 0, 0.3))
	rect(img, 12, 0, 12, 8, OUT)
	rect(img, 13, 0, 10, 7, STONE_D)
	rect(img, 3, 6, 30, 26, OUT)
	rect(img, 4, 7, 28, 24, STONE_M)
	rect(img, 4, 7, 28, 2, STONE_L)
	# Brick seams.
	for y in range(11, 30, 5):
		rect(img, 4, y, 28, 1, STONE_D)
		for x in range(6 + (y % 2) * 5, 32, 10):
			rect(img, x, y, 1, 5, STONE_D)
	# Glowing mouth.
	rect(img, 9, 15, 18, 15, OUT)
	rect(img, 10, 16, 16, 14, Color("5a1f10"))
	ellipse(img, 18, 27, 7, 5, FIRE)
	ellipse(img, 18, 27, 4.5, 3, FIRE_L)
	for x in [12, 16, 20, 23]:
		rect(img, x, 22, 2, 3, FIRE)
	_cache["forge"] = tex(img)
	return _cache["forge"]


# A wall torch; two flame frames. Origin is the top-left; 8x18.
static func torch(frame: int) -> Texture2D:
	var key := "torch_%d" % frame
	if _cache.has(key):
		return _cache[key]
	var img := canvas(8, 18)
	rect(img, 2, 8, 4, 3, OUT)
	rect(img, 3, 9, 2, 1, IRON_L)
	rect(img, 3, 10, 2, 8, OUT)
	rect(img, 3, 11, 2, 6, WOOD_M)
	var lean := 0 if frame == 0 else 1
	ellipse(img, 4 + lean * 0.5, 5, 3, 4.5, OUT)
	ellipse(img, 4 + lean * 0.5, 5.5, 2.2, 3.7, FIRE)
	ellipse(img, 4 + lean * 0.5, 6.5, 1.2, 2.2, FIRE_L)
	put(img, 4 + lean, 0, FIRE)
	_cache[key] = tex(img)
	return _cache[key]


# ---------- boss chamber ----------

# A glowing rune ring for the boss arena, `rx` x `ry` px radius. Origin is the centre.
static func rune_circle(rx: int, ry: int) -> Texture2D:
	var key := "rune_%d_%d" % [rx, ry]
	if _cache.has(key):
		return _cache[key]
	var w := rx * 2 + 8
	var h := ry * 2 + 8
	var img := canvas(w, h)
	var cx := w / 2.0
	var cy := h / 2.0
	var glow := Color("b86bff")
	var dark := Color("3a1f5c")
	for y in h:
		for x in w:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var d := dx * dx + dy * dy
			if d <= 1.0 and d >= 0.9:
				put(img, x, y, glow if d < 0.96 else dark)
			elif d <= 0.74 and d >= 0.68:
				put(img, x, y, Color(glow, 0.8))
			elif d <= 0.42 and d >= 0.38:
				put(img, x, y, Color(glow, 0.55))
	# Spokes and tick marks.
	for k in 16:
		var a := TAU * k / 16.0
		for r in [0.82, 0.86, 0.9]:
			put(img, roundi(cx + rx * r * cos(a)), roundi(cy + ry * r * sin(a)), GOLD if k % 2 == 0 else glow)
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0
		for r in [0.45, 0.52, 0.59, 0.66]:
			put(img, roundi(cx + rx * r * cos(a)), roundi(cy + ry * r * sin(a)), Color(glow, 0.7))
	_cache[key] = tex(img)
	return _cache[key]


# body, light, dark, lock colours, and the glow colour, for each look of treasure chest.
const CHEST_STYLES := {
	"royal": [Color("5b3fa0"), Color("7d5cc9"), Color("3d2870"), Color("5de08a"), Color(1.0, 0.85, 0.4)],
	"frost": [Color("3f78c0"), Color("7db8f0"), Color("264f8a"), Color("c8f4ff"), Color(0.6, 0.9, 1.0)],
	"sand": [Color("c9a24a"), Color("f0cf7a"), Color("8a6a28"), Color("3fd0c0"), Color(1.0, 0.8, 0.35)],
	"sea": [Color("6b4423"), Color("8a5a2b"), Color("3e2713"), Color("e8c872"), Color(0.5, 0.85, 1.0)],
	"bog": [Color("3e6b3a"), Color("5f9a50"), Color("24421f"), Color("c06bff"), Color(0.6, 1.0, 0.5)],
}


static func chest_glow(style: String) -> Color:
	return CHEST_STYLES.get(style, CHEST_STYLES["royal"])[4]


# The King Slime's treasure chest: purple with gold bands and a slime-green lock. Origin is the
# bottom-centre; 28x26. When open the lid is propped up and the inside shines.
static func royal_chest(open: bool, style := "royal") -> Texture2D:
	var key := "royal_%s_%s" % [open, style]
	if _cache.has(key):
		return _cache[key]
	var img := canvas(28, 26)
	var pal: Array = CHEST_STYLES.get(style, CHEST_STYLES["royal"])
	var purple: Color = pal[0]
	var purple_l: Color = pal[1]
	var purple_d: Color = pal[2]
	var green: Color = pal[3]
	ellipse(img, 14, 24, 12, 2, Color(0, 0, 0, 0.3))
	# Body.
	rect(img, 2, 12, 24, 12, OUT)
	rect(img, 3, 13, 22, 10, purple)
	rect(img, 3, 13, 22, 2, purple_l)
	rect(img, 3, 21, 22, 2, purple_d)
	rect(img, 6, 13, 2, 10, GOLD)
	rect(img, 20, 13, 2, 10, GOLD)
	if open:
		# Lid swung back, with light spilling out of the chest.
		rect(img, 2, 2, 24, 6, OUT)
		rect(img, 3, 3, 22, 4, purple_d)
		rect(img, 3, 3, 22, 1, purple)
		rect(img, 6, 3, 2, 4, GOLD)
		rect(img, 20, 3, 2, 4, GOLD)
		rect(img, 3, 8, 22, 5, OUT)
		rect(img, 4, 9, 20, 4, GLASS_L)
		rect(img, 6, 9, 16, 2, FOAM)
		for x in [8, 13, 18]:
			rect(img, x, 7, 2, 2, GLASS)
	else:
		# Rounded lid.
		rect(img, 2, 6, 24, 7, OUT)
		rect(img, 3, 7, 22, 5, purple)
		rect(img, 3, 7, 22, 1, purple_l)
		rect(img, 6, 7, 2, 5, GOLD)
		rect(img, 20, 7, 2, 5, GOLD)
		rect(img, 4, 5, 20, 2, OUT)
		rect(img, 5, 6, 18, 1, purple_l)
		# Slime-green lock.
		rect(img, 11, 10, 6, 6, OUT)
		rect(img, 12, 11, 4, 4, green)
		put(img, 13, 12, FOAM)
		put(img, 13, 14, OUT)
		put(img, 14, 14, OUT)
	_cache[key] = tex(img)
	return _cache[key]


# ---------- power-up orbs ----------

const ORB_COLORS := {
	"rage": Color("e0463a"), "swift": Color("37c8d9"), "aegis": Color("e8b53a"), "heart": Color("ee6f9a"),
}
const ORB_ICONS := {
	"rage": [".X.X.", ".XXX.", "XXXXX", "XXXXX", ".XXX."],
	"swift": ["...X.", "..XX.", ".XXXX", "..XX.", "..X.."],
	"aegis": ["XXXXX", "XXXXX", "XXXXX", ".XXX.", "..X.."],
	"heart": [".X.X.", "XXXXX", "XXXXX", ".XXX.", "..X.."],
}


static func orb(kind: String) -> Texture2D:
	var key := "orb_" + kind
	if _cache.has(key):
		return _cache[key]
	var img := canvas(16, 16)
	var base: Color = ORB_COLORS[kind]
	ellipse(img, 8, 8, 7.5, 7.5, OUT)
	ellipse(img, 8, 8, 6.5, 6.5, base.darkened(0.25))
	ellipse(img, 7.5, 7.5, 5.5, 5.5, base)
	ellipse(img, 6, 5.5, 2.2, 1.6, base.lightened(0.55))
	var icon: Array = ORB_ICONS[kind]
	for y in icon.size():
		var row: String = icon[y]
		for x in row.length():
			if row[x] == "X":
				put(img, 5 + x, 5 + y + 1, Color.WHITE if kind != "aegis" else Color("fff6d0"))
	_cache[key] = tex(img)
	return _cache[key]


# ---------- wizard's study ----------

# Wooden floorboards, `tw` x `th` tiles. Origin is the top-left.
static func plank_floor(tw: int, th: int) -> Texture2D:
	var key := "planks_%d_%d" % [tw, th]
	if _cache.has(key):
		return _cache[key]
	var img := canvas(tw * 16, th * 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var tones := [Color("7a5230"), Color("85582f"), Color("6e4a2a"), Color("8b6034")]
	for row in th * 4:
		var y := row * 4
		var offset := (row * 7) % 16
		var x := -offset
		while x < tw * 16:
			var len := 12 + rng.randi_range(0, 3) * 4
			var tone: Color = tones[rng.randi() % tones.size()]
			rect(img, x, y, len, 4, tone)
			rect(img, x, y, len, 1, tone.lightened(0.12))
			rect(img, x, y + 3, len, 1, tone.darkened(0.25))
			rect(img, x + len - 1, y, 1, 4, tone.darkened(0.3))
			put(img, x + 2, y + 1, tone.darkened(0.35))
			put(img, x + len - 3, y + 2, tone.darkened(0.35))
			x += len
	_cache[key] = tex(img)
	return _cache[key]


# A tall bookshelf crammed with books and bottles. Origin is the top-left; 32x38.
static func bookshelf(seed_value: int) -> Texture2D:
	var key := "books_%d" % seed_value
	if _cache.has(key):
		return _cache[key]
	var img := canvas(32, 38)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	rect(img, 0, 0, 32, 38, OUT)
	rect(img, 1, 1, 30, 36, WOOD_D)
	rect(img, 1, 1, 30, 2, WOOD_M)
	var spines := [Color("b4423a"), Color("3a6fb4"), Color("4f9d4f"), Color("c7a23a"), Color("8a4fb4"), Color("d9d4c0")]
	for shelf in 3:
		var y0 := 3 + shelf * 11
		rect(img, 2, y0 + 9, 28, 2, WOOD_M)
		rect(img, 2, y0 + 10, 28, 1, WOOD_L)
		var x := 3
		while x < 28:
			if rng.randf() < 0.14:
				# A potion bottle.
				var c: Color = spines[rng.randi() % spines.size()]
				rect(img, x + 1, y0 + 4, 3, 5, OUT)
				rect(img, x + 2, y0 + 5, 1, 3, c.lightened(0.2))
				rect(img, x + 2, y0 + 3, 1, 2, FOAM)
				x += 5
			else:
				var w := rng.randi_range(2, 4)
				var h := rng.randi_range(6, 8)
				var c: Color = spines[rng.randi() % spines.size()]
				rect(img, x, y0 + 9 - h, w, h, OUT)
				rect(img, x, y0 + 9 - h, w - 1, h, c)
				rect(img, x, y0 + 10 - h, w - 1, 1, c.lightened(0.3))
				if rng.randf() < 0.4:
					rect(img, x, y0 + 9 - h / 2, w - 1, 1, GOLD)
				x += w
	_cache[key] = tex(img)
	return _cache[key]


# A bubbling green cauldron on a little fire. Origin is the bottom-centre; 28x28.
static func cauldron() -> Texture2D:
	if _cache.has("cauldron"):
		return _cache["cauldron"]
	var img := canvas(28, 28)
	ellipse(img, 14, 26, 12, 2, Color(0, 0, 0, 0.3))
	# Fire under the pot.
	ellipse(img, 14, 23, 7, 3, OUT)
	ellipse(img, 14, 23, 5, 2, FIRE)
	ellipse(img, 14, 23, 2.5, 1.2, FIRE_L)
	# Pot body and legs.
	ellipse(img, 14, 14, 12, 10, OUT)
	ellipse(img, 14, 14, 11, 9, IRON)
	ellipse(img, 11, 12, 6, 5, IRON_L)
	rect(img, 5, 20, 3, 4, OUT)
	rect(img, 20, 20, 3, 4, OUT)
	# Rim and the glowing potion.
	ellipse(img, 14, 6, 11, 4.5, OUT)
	ellipse(img, 14, 6, 10, 3.5, IRON_L)
	ellipse(img, 14, 6, 8.5, 2.6, Color("2f9a4a"))
	ellipse(img, 14, 6, 6, 1.6, Color("5de08a"))
	for p in [Vector2i(10, 5), Vector2i(15, 6), Vector2i(18, 5), Vector2i(12, 7)]:
		put(img, p.x, p.y, Color("c8ffd8"))
	_cache["cauldron"] = tex(img)
	return _cache["cauldron"]


# A crystal ball on a carved pedestal. Origin is the bottom-centre; 20x30.
static func crystal_ball() -> Texture2D:
	if _cache.has("crystal"):
		return _cache["crystal"]
	var img := canvas(20, 30)
	ellipse(img, 10, 28, 8, 2, Color(0, 0, 0, 0.3))
	rect(img, 5, 24, 10, 5, OUT)
	rect(img, 6, 25, 8, 3, STONE_M)
	rect(img, 6, 25, 8, 1, STONE_L)
	rect(img, 7, 17, 6, 8, OUT)
	rect(img, 8, 18, 4, 6, STONE_M)
	rect(img, 8, 18, 1, 6, STONE_L)
	ellipse(img, 10, 10, 9, 9, OUT)
	ellipse(img, 10, 10, 8, 8, Color("5b6fd0"))
	ellipse(img, 10, 11, 6, 6, Color("8a6bf0"))
	ellipse(img, 7, 7, 3, 2.5, Color("d6dcff"))
	put(img, 13, 13, FOAM)
	put(img, 12, 14, FOAM)
	_cache["crystal"] = tex(img)
	return _cache["crystal"]


# ---------- smithy ----------

# A round grindstone on a wooden frame. Origin is the bottom-centre; 24x22.
static func grindstone() -> Texture2D:
	if _cache.has("grindstone"):
		return _cache["grindstone"]
	var img := canvas(24, 22)
	ellipse(img, 12, 20, 10, 2, Color(0, 0, 0, 0.3))
	rect(img, 3, 8, 3, 13, OUT)
	rect(img, 4, 9, 1, 11, WOOD_M)
	rect(img, 18, 8, 3, 13, OUT)
	rect(img, 19, 9, 1, 11, WOOD_M)
	ellipse(img, 12, 10, 9, 9, OUT)
	ellipse(img, 12, 10, 8, 8, STONE_M)
	ellipse(img, 10, 8, 5, 5, STONE_L)
	ellipse(img, 12, 10, 2, 2, OUT)
	for p in [Vector2i(16, 6), Vector2i(17, 12), Vector2i(8, 15), Vector2i(7, 9)]:
		put(img, p.x, p.y, STONE_D)
	_cache["grindstone"] = tex(img)
	return _cache["grindstone"]


# ---------- shooting gallery ----------

# A bullseye target: red and white rings around a gold centre. The golden version is worth more.
static func target(golden: bool) -> Texture2D:
	var key := "target_%s" % golden
	if _cache.has(key):
		return _cache[key]
	var img := canvas(34, 34)
	var rings: Array = [
		[1.0, OUT],
		[0.94, Color("f2c14e") if golden else Color("d63c3c")],
		[0.78, Color("fff6d0") if golden else Color("f5f5f5")],
		[0.62, Color("e8a21a") if golden else Color("d63c3c")],
		[0.46, Color("fff6d0") if golden else Color("f5f5f5")],
		[0.30, OUT],
		[0.26, Color("ffdd55") if golden else Color("f2c14e")],
	]
	for r in rings:
		ellipse(img, 17, 17, 17.0 * r[0], 17.0 * r[0], r[1])
	if golden:
		for p in [Vector2i(9, 8), Vector2i(24, 10), Vector2i(11, 24), Vector2i(23, 22)]:
			put(img, p.x, p.y, Color.WHITE)
			put(img, p.x + 1, p.y, Color(1, 1, 1, 0.6))
			put(img, p.x, p.y + 1, Color(1, 1, 1, 0.6))
	_cache[key] = tex(img)
	return _cache[key]


static func crosshair() -> Texture2D:
	if _cache.has("crosshair"):
		return _cache["crosshair"]
	var img := canvas(17, 17)
	for pass_index in 2:
		var col := OUT if pass_index == 0 else Color.WHITE
		var grow := 1 if pass_index == 0 else 0
		for a in 24:
			var ang := TAU * a / 24.0
			rect(img, roundi(8 + cos(ang) * 6) - grow, roundi(8 + sin(ang) * 6) - grow, 1 + grow * 2, 1 + grow * 2, col)
		rect(img, 8 - grow, 0, 1 + grow * 2, 4, col)
		rect(img, 8 - grow, 13, 1 + grow * 2, 4, col)
		rect(img, 0, 8 - grow, 4, 1 + grow * 2, col)
		rect(img, 13, 8 - grow, 4, 1 + grow * 2, col)
	put(img, 8, 8, Color("e84a5f"))
	_cache["crosshair"] = tex(img)
	return _cache["crosshair"]


# ---------- bakery ----------

# Cream and rose checkered tiles. Origin is the top-left.
static func checker_floor(tw: int, th: int) -> Texture2D:
	var key := "checker_%d_%d" % [tw, th]
	if _cache.has(key):
		return _cache[key]
	var img := canvas(tw * 16, th * 16)
	var light := Color("f6e6cc")
	var rose := Color("eec3b4")
	for ty in th:
		for tx in tw:
			var base := light if (tx + ty) % 2 == 0 else rose
			rect(img, tx * 16, ty * 16, 16, 16, base)
			rect(img, tx * 16, ty * 16, 16, 1, base.lightened(0.15))
			rect(img, tx * 16, ty * 16 + 15, 16, 1, base.darkened(0.14))
			rect(img, tx * 16 + 15, ty * 16, 1, 16, base.darkened(0.14))
	_cache[key] = tex(img)
	return _cache[key]


# A brick oven with a glowing arched mouth. Origin is the bottom-centre; 40x40.
static func oven() -> Texture2D:
	if _cache.has("oven"):
		return _cache["oven"]
	var img := canvas(40, 40)
	var brick := Color("b5573e")
	ellipse(img, 20, 38, 18, 2, Color(0, 0, 0, 0.3))
	rect(img, 15, 0, 10, 10, OUT)
	rect(img, 16, 0, 8, 9, brick.darkened(0.2))
	ellipse(img, 20, 20, 19, 17, OUT)
	rect(img, 1, 20, 38, 18, OUT)
	ellipse(img, 20, 20, 18, 16, brick)
	rect(img, 2, 20, 36, 17, brick)
	for y in range(8, 37, 5):
		rect(img, 3, y, 34, 1, brick.darkened(0.25))
		for x in range(4 + (y % 2) * 4, 37, 8):
			rect(img, x, y, 1, 5, brick.darkened(0.25))
	rect(img, 2, 8, 36, 2, brick.lightened(0.15))
	ellipse(img, 20, 27, 10, 9, OUT)
	rect(img, 10, 27, 20, 10, OUT)
	ellipse(img, 20, 27, 9, 8, Color("5a1f10"))
	rect(img, 11, 27, 18, 9, Color("5a1f10"))
	ellipse(img, 20, 33, 7, 4, FIRE)
	ellipse(img, 20, 33, 4, 2.4, FIRE_L)
	for x in [13, 17, 23, 26]:
		rect(img, x, 29, 2, 3, FIRE)
	_cache["oven"] = tex(img)
	return _cache["oven"]


# A wall shelf stacked with loaves, baguettes and rolls. Origin is the top-left; 40x30.
static func bread_shelf() -> Texture2D:
	if _cache.has("bread_shelf"):
		return _cache["bread_shelf"]
	var img := canvas(40, 30)
	rect(img, 0, 0, 40, 30, OUT)
	rect(img, 1, 1, 38, 28, WOOD_D)
	rect(img, 1, 1, 38, 2, WOOD_M)
	var crust := Color("d9953c")
	var crust_d := Color("a8662a")
	var crust_l := Color("f2c070")
	for shelf in 2:
		var y := 4 + shelf * 13
		rect(img, 1, y + 9, 38, 2, WOOD_M)
		rect(img, 1, y + 10, 38, 1, WOOD_L)
		# Round loaves.
		for x in [6, 15]:
			ellipse(img, x + 4, y + 5, 5.5, 4.5, OUT)
			ellipse(img, x + 4, y + 5, 4.5, 3.6, crust)
			ellipse(img, x + 3, y + 4, 2.5, 1.6, crust_l)
			put(img, x + 4, y + 4, crust_d)
			put(img, x + 6, y + 5, crust_d)
		# Baguettes leaning in a basket.
		for k in 3:
			rect(img, 26 + k * 3, y - 1 + k, 2, 10 - k, OUT)
			rect(img, 27 + k * 3, y + k, 1, 8 - k, crust)
		rect(img, 24, y + 6, 12, 3, OUT)
		rect(img, 25, y + 7, 10, 1, WOOD_M)
	_cache["bread_shelf"] = tex(img)
	return _cache["bread_shelf"]


# A glass pastry case that sits on top of the counter, `tiles` wide. Origin is the top-left.
static func pastry_case(tiles: int) -> Texture2D:
	var key := "pastry_%d" % tiles
	if _cache.has(key):
		return _cache[key]
	var w := tiles * 16
	var img := canvas(w, 18)
	rect(img, 0, 2, w, 16, OUT)
	rect(img, 1, 3, w - 2, 14, Color(0.8, 0.92, 1.0, 0.55))
	rect(img, 1, 3, w - 2, 2, Color(1, 1, 1, 0.6))
	var items := [
		[Color("e8a2b8"), Color("fff0f4")], [Color("c98a4a"), Color("f0c585")],
		[Color("a35a8a"), Color("f2a8d8")], [Color("d9953c"), Color("f6d58a")],
	]
	var i := 0
	for x in range(6, w - 8, 14):
		var it: Array = items[i % items.size()]
		ellipse(img, x + 4, 12, 5.5, 3.6, OUT)
		ellipse(img, x + 4, 12, 4.6, 2.8, it[0])
		ellipse(img, x + 3, 10.5, 2.6, 1.5, it[1])
		put(img, x + 4, 8, Color("e84a5f"))
		i += 1
	rect(img, 0, 0, w, 3, OUT)
	rect(img, 1, 1, w - 2, 1, WOOD_L)
	_cache[key] = tex(img)
	return _cache[key]


# A round café table with a gingham cloth, a plate of cake and two little chairs. Origin: bottom-centre; 40x30.
static func cafe_table() -> Texture2D:
	if _cache.has("cafe_table"):
		return _cache["cafe_table"]
	var img := canvas(40, 30)
	ellipse(img, 20, 26, 17, 3, Color(0, 0, 0, 0.28))
	# Chairs at the sides.
	for x in [3, 29]:
		rect(img, x, 8, 8, 17, OUT)
		rect(img, x + 1, 9, 6, 6, WOOD_M)
		rect(img, x + 1, 16, 6, 8, WOOD_D)
	# Table: pedestal and a round top with a checked cloth.
	rect(img, 17, 18, 6, 9, OUT)
	rect(img, 18, 19, 4, 7, WOOD_M)
	ellipse(img, 20, 13, 15, 8, OUT)
	ellipse(img, 20, 13, 14, 7, Color("f5f5f5"))
	for ty in range(7, 20, 3):
		for tx in range(8, 33, 3):
			if (tx / 3 + ty / 3) % 2 == 0:
				var dx := (tx - 20) / 14.0
				var dy := (ty - 13) / 7.0
				if dx * dx + dy * dy < 0.85:
					rect(img, tx, ty, 3, 3, Color("e8707f"))
	ellipse(img, 20, 12, 6, 3.2, OUT)
	ellipse(img, 20, 12, 5, 2.4, Color("fff0f4"))
	ellipse(img, 20, 11, 3, 1.6, Color("e8a2b8"))
	put(img, 20, 9, Color("e84a5f"))
	rect(img, 29, 9, 4, 4, OUT)
	rect(img, 30, 10, 2, 2, Color("8a5a2b"))
	_cache["cafe_table"] = tex(img)
	return _cache["cafe_table"]


# ---------- town hall ----------

# Polished marble in two pale tones. Origin is the top-left.
static func marble_floor(tw: int, th: int) -> Texture2D:
	var key := "marble_%d_%d" % [tw, th]
	if _cache.has(key):
		return _cache[key]
	var img := canvas(tw * 16, th * 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for ty in th:
		for tx in tw:
			var base := Color("dfe5ef") if (tx + ty) % 2 == 0 else Color("c9d2e2")
			rect(img, tx * 16, ty * 16, 16, 16, base)
			rect(img, tx * 16, ty * 16, 16, 1, base.lightened(0.2))
			rect(img, tx * 16, ty * 16, 1, 16, base.lightened(0.12))
			rect(img, tx * 16, ty * 16 + 15, 16, 1, base.darkened(0.16))
			rect(img, tx * 16 + 15, ty * 16, 1, 16, base.darkened(0.16))
			# Marble veins.
			var vx := tx * 16 + rng.randi_range(2, 12)
			var vy := ty * 16 + rng.randi_range(2, 12)
			for k in rng.randi_range(3, 6):
				put(img, vx + k, vy + int(k * 0.6), base.darkened(0.1))
	_cache[key] = tex(img)
	return _cache[key]


# The mayor's big desk with papers, an inkwell and a quill. Origin is the top-left; `tiles` wide, 28 tall.
static func desk(tiles: int) -> Texture2D:
	var key := "desk_%d" % tiles
	if _cache.has(key):
		return _cache[key]
	var w := tiles * 16
	var img := canvas(w, 30)
	rect(img, 0, 0, w, 27, OUT)
	rect(img, 1, 1, w - 2, 10, WOOD_L)
	rect(img, 1, 11, w - 2, 1, WOOD_D)
	rect(img, 1, 12, w - 2, 14, WOOD_M)
	for x in range(10, w - 2, 20):
		rect(img, x, 12, 1, 14, WOOD_D)
		rect(img, x - 4, 17, 8, 4, WOOD_D)
		rect(img, x - 3, 18, 6, 2, GOLD_D)
	rect(img, 1, 25, w - 2, 1, WOOD_D)
	# Papers, a stamp, ink and a quill.
	rect(img, 8, 2, 14, 8, OUT)
	rect(img, 9, 3, 12, 6, Color("f5f0e0"))
	for y in [4, 6]:
		rect(img, 10, y, 8, 1, Color("8a86a6"))
	rect(img, w - 30, 3, 10, 6, OUT)
	rect(img, w - 29, 4, 8, 4, Color("f5f0e0"))
	rect(img, w - 14, 4, 6, 6, OUT)
	rect(img, w - 13, 5, 4, 4, Color("2a2540"))
	rect(img, w - 11, 0, 2, 5, Color("f5f5f5"))
	put(img, w - 10, 0, RED)
	ellipse(img, w / 2.0, 26, w / 2.0 - 2, 2, Color(0, 0, 0, 0.25))
	_cache[key] = tex(img)
	return _cache[key]


# A cork notice board pinned with quest notes. Origin is the top-left; 52x36.
static func notice_board() -> Texture2D:
	if _cache.has("notice"):
		return _cache["notice"]
	var img := canvas(52, 36)
	rect(img, 0, 0, 52, 36, OUT)
	rect(img, 1, 1, 50, 34, WOOD_M)
	rect(img, 3, 3, 46, 30, Color("b88a55"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in 60:
		put(img, rng.randi_range(3, 48), rng.randi_range(3, 32), Color("9c703f"))
	var notes := [
		[6, 6, Color("f5f0e0")], [20, 5, Color("ffe08a")], [34, 7, Color("f5f0e0")],
		[10, 19, Color("ffd1d9")], [25, 18, Color("f5f0e0")], [38, 19, Color("c8ecff")],
	]
	for n in notes:
		rect(img, n[0], n[1], 11, 11, OUT)
		rect(img, n[0] + 1, n[1] + 1, 9, 9, n[2])
		for l in 3:
			rect(img, n[0] + 2, n[1] + 3 + l * 2, 6, 1, Color("8a86a6"))
		put(img, n[0] + 5, n[1] + 1, Color("e84a5f"))
	_cache["notice"] = tex(img)
	return _cache["notice"]


# A marble pillar. Origin is the bottom-centre; 18x46.
static func pillar() -> Texture2D:
	if _cache.has("pillar"):
		return _cache["pillar"]
	var img := canvas(18, 46)
	ellipse(img, 9, 44, 8, 2, Color(0, 0, 0, 0.3))
	rect(img, 1, 38, 16, 7, OUT)
	rect(img, 2, 39, 14, 5, STONE_M)
	rect(img, 2, 39, 14, 1, STONE_L)
	rect(img, 3, 6, 12, 33, OUT)
	rect(img, 4, 6, 10, 33, STONE_L)
	rect(img, 4, 6, 3, 33, FOAM)
	rect(img, 11, 6, 3, 33, STONE_M)
	for x in [8, 10]:
		rect(img, x, 8, 1, 29, STONE_M)
	rect(img, 0, 0, 18, 8, OUT)
	rect(img, 1, 1, 16, 6, STONE_M)
	rect(img, 1, 1, 16, 2, STONE_L)
	rect(img, 2, 7, 14, 1, STONE_D)
	_cache["pillar"] = tex(img)
	return _cache["pillar"]


# A glass trophy cabinet with cups, a medal and a little sword. Origin is the top-left; 40x44.
static func trophy_case() -> Texture2D:
	if _cache.has("trophy"):
		return _cache["trophy"]
	var img := canvas(40, 44)
	rect(img, 0, 0, 40, 44, OUT)
	rect(img, 1, 1, 38, 42, WOOD_D)
	rect(img, 3, 4, 34, 36, Color(0.78, 0.9, 1.0, 0.5))
	rect(img, 3, 4, 34, 36, Color("2a2f4a"))
	rect(img, 3, 4, 34, 36, Color(0.78, 0.9, 1.0, 0.18))
	rect(img, 3, 22, 34, 2, WOOD_M)
	# Cup on the top shelf.
	rect(img, 9, 9, 10, 8, OUT)
	rect(img, 10, 9, 8, 7, GOLD)
	rect(img, 10, 9, 2, 7, FOAM)
	rect(img, 7, 10, 3, 4, GOLD_D)
	rect(img, 18, 10, 3, 4, GOLD_D)
	rect(img, 12, 16, 4, 4, GOLD_D)
	rect(img, 9, 19, 10, 3, OUT)
	rect(img, 10, 19, 8, 2, GOLD_D)
	# Medal and small sword.
	ellipse(img, 29, 13, 4.5, 4.5, OUT)
	ellipse(img, 29, 13, 3.5, 3.5, GOLD)
	put(img, 28, 12, FOAM)
	rect(img, 28, 17, 3, 4, RED)
	rect(img, 8, 28, 24, 3, OUT)
	rect(img, 9, 29, 16, 1, STONE_L)
	rect(img, 25, 27, 2, 5, GOLD_D)
	rect(img, 27, 29, 4, 1, WOOD_L)
	# Crown on the bottom shelf.
	for k in 3:
		rect(img, 14 + k * 4, 34, 3, 3, GOLD)
	rect(img, 14, 36, 11, 3, GOLD)
	rect(img, 14, 38, 11, 1, GOLD_D)
	rect(img, 3, 22, 34, 1, WOOD_L)
	_cache["trophy"] = tex(img)
	return _cache["trophy"]


# A standing mirror in a carved wooden frame. Origin is the bottom-centre; 26x44.
static func mirror() -> Texture2D:
	if _cache.has("mirror"):
		return _cache["mirror"]
	var img := canvas(26, 44)
	ellipse(img, 13, 42, 11, 2, Color(0, 0, 0, 0.3))
	rect(img, 2, 36, 3, 7, OUT)
	rect(img, 21, 36, 3, 7, OUT)
	ellipse(img, 13, 18, 12, 18, OUT)
	ellipse(img, 13, 18, 11, 17, WOOD_L)
	ellipse(img, 13, 18, 9, 15, OUT)
	ellipse(img, 13, 18, 8, 14, Color("bfe3f5"))
	ellipse(img, 13, 22, 6, 10, Color("d9f1fb"))
	for k in 6:
		put(img, 9 + k, 8 + k * 2, FOAM)
		put(img, 8 + k, 8 + k * 2, Color(1, 1, 1, 0.6))
	for p in [Vector2i(13, 1), Vector2i(1, 18), Vector2i(25, 18)]:
		rect(img, p.x - 1, p.y - 1, 3, 3, GOLD)
	_cache["mirror"] = tex(img)
	return _cache["mirror"]


# A big hand-drawn map pinned to the wall. Origin is the top-left; 52x36.
static func map_board() -> Texture2D:
	if _cache.has("map"):
		return _cache["map"]
	var img := canvas(52, 36)
	rect(img, 0, 0, 52, 36, OUT)
	rect(img, 1, 1, 50, 34, Color("e8d3a0"))
	rect(img, 1, 1, 50, 2, Color("f2e2b8"))
	rect(img, 1, 33, 50, 2, Color("c4a870"))
	# Land, water and forest.
	ellipse(img, 26, 18, 21, 13, Color("9bc269"))
	ellipse(img, 36, 24, 9, 6, Color("5aa9ff"))
	ellipse(img, 10, 24, 5, 4, Color("7fae55"))
	for p in [Vector2i(10, 10), Vector2i(14, 8), Vector2i(40, 9), Vector2i(44, 12)]:
		rect(img, p.x, p.y, 3, 4, Color("3e8a3a"))
	# A road, the town, a cave and an X.
	for x in range(6, 44):
		put(img, x, 19 + int(sin(x * 0.3) * 1.5), Color("c9a063"))
	rect(img, 21, 14, 7, 6, OUT)
	rect(img, 22, 15, 5, 4, Color("d6736a"))
	rect(img, 41, 15, 6, 6, OUT)
	rect(img, 42, 16, 4, 4, Color("2a2540"))
	for k in 5:
		put(img, 7 + k, 12 + k, Color("c0392b"))
		put(img, 11 - k, 12 + k, Color("c0392b"))
	_cache["map"] = tex(img)
	return _cache["map"]


# A straw training dummy on a wooden post. Origin is the bottom-centre; 24x34.
static func training_dummy() -> Texture2D:
	if _cache.has("dummy"):
		return _cache["dummy"]
	var img := canvas(24, 34)
	ellipse(img, 12, 32, 10, 2, Color(0, 0, 0, 0.3))
	rect(img, 10, 14, 4, 18, OUT)
	rect(img, 11, 14, 2, 17, WOOD_M)
	rect(img, 3, 14, 18, 4, OUT)
	rect(img, 4, 15, 16, 2, WOOD_L)
	rect(img, 6, 11, 12, 14, OUT)
	rect(img, 7, 12, 10, 12, Color("d9b86a"))
	rect(img, 7, 12, 3, 12, Color("f0d890"))
	for y in [15, 19, 23]:
		rect(img, 7, y, 10, 1, Color("b89548"))
	ellipse(img, 12, 6, 6, 6, OUT)
	ellipse(img, 12, 6, 5, 5, Color("d9b86a"))
	ellipse(img, 12, 6, 3.4, 3.4, RED)
	ellipse(img, 12, 6, 2, 2, Color("f5f5f5"))
	put(img, 12, 6, RED)
	_cache["dummy"] = tex(img)
	return _cache["dummy"]


# A little pile of coins and a money bag for the bank counter. Origin is the bottom-centre; 22x14.
static func coin_pile() -> Texture2D:
	if _cache.has("coins"):
		return _cache["coins"]
	var img := canvas(22, 14)
	ellipse(img, 7, 10, 6, 3.4, OUT)
	ellipse(img, 7, 10, 5, 2.6, GOLD)
	ellipse(img, 6, 8, 4, 2.4, OUT)
	ellipse(img, 6, 8, 3, 1.6, GOLD_D)
	ellipse(img, 7, 6, 3, 1.5, OUT)
	ellipse(img, 7, 6, 2, 0.9, GOLD)
	ellipse(img, 16, 8, 4.5, 5, OUT)
	ellipse(img, 16, 8, 3.6, 4.2, Color("a8802a"))
	rect(img, 14, 3, 5, 2, OUT)
	rect(img, 14, 4, 5, 1, GOLD)
	put(img, 16, 8, GOLD)
	_cache["coins"] = tex(img)
	return _cache["coins"]


# ---------- cooking ----------

# A black pot of stew hanging over a campfire on a tripod. Origin is the bottom-centre; 36x38.
static func campfire_pot() -> Texture2D:
	if _cache.has("campfire"):
		return _cache["campfire"]
	var img := canvas(36, 38)
	ellipse(img, 18, 36, 15, 2, Color(0, 0, 0, 0.3))
	# Tripod legs.
	for k in 6:
		put(img, 7 + k, 6 + k * 3, OUT)
		put(img, 8 + k, 6 + k * 3, WOOD_M)
		put(img, 28 - k, 6 + k * 3, OUT)
		put(img, 27 - k, 6 + k * 3, WOOD_M)
	rect(img, 6, 3, 24, 3, OUT)
	rect(img, 7, 4, 22, 1, WOOD_L)
	# Logs and fire.
	rect(img, 6, 31, 24, 4, OUT)
	rect(img, 7, 32, 22, 2, WOOD_M)
	rect(img, 9, 29, 18, 3, OUT)
	rect(img, 10, 30, 16, 1, WOOD_D)
	ellipse(img, 18, 27, 8, 5, OUT)
	ellipse(img, 18, 27, 7, 4, FIRE)
	ellipse(img, 18, 27, 4, 2.6, FIRE_L)
	for x in [12, 16, 20, 24]:
		rect(img, x, 22 + (x % 3), 2, 4, FIRE)
	# The pot.
	ellipse(img, 18, 17, 11, 9, OUT)
	ellipse(img, 18, 17, 10, 8, IRON)
	ellipse(img, 14, 15, 5, 4, IRON_L)
	ellipse(img, 18, 10, 11, 4, OUT)
	ellipse(img, 18, 10, 10, 3, IRON_L)
	ellipse(img, 18, 10, 8.5, 2.4, Color("c0763a"))
	ellipse(img, 18, 10, 5.5, 1.4, Color("e8a050"))
	for q in [Vector2i(13, 10), Vector2i(18, 11), Vector2i(21, 9)]:
		put(img, q.x, q.y, Color("fff0c8"))
	_cache["campfire"] = tex(img)
	return _cache["campfire"]


# ---------- frozen caves ----------

# Cracked blue ice with patches of snow. Origin is the top-left.
static func ice_floor(tw: int, th: int) -> Texture2D:
	var key := "ice_%d_%d" % [tw, th]
	if _cache.has(key):
		return _cache[key]
	var w := tw * 16
	var h := th * 16
	var img := canvas(w, h)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var tones := [Color("9fd4f0"), Color("8cc6e8"), Color("a8dcf5"), Color("86bde0")]
	for ty in th:
		for tx in tw:
			var base: Color = tones[(tx * 7 + ty * 3 + rng.randi() % 2) % tones.size()]
			rect(img, tx * 16, ty * 16, 16, 16, base)
			rect(img, tx * 16, ty * 16, 16, 1, base.lightened(0.15))
			rect(img, tx * 16, ty * 16, 1, 16, base.lightened(0.1))
			for i in 5:
				put(img, tx * 16 + rng.randi_range(1, 14), ty * 16 + rng.randi_range(1, 14), base.lightened(0.25) if rng.randf() < 0.6 else base.darkened(0.1))
	# Cracks.
	for c in int(w * h / 3200.0):
		var x := rng.randi_range(8, w - 8)
		var y := rng.randi_range(8, h - 8)
		var dx := rng.randi_range(-1, 1)
		for k in rng.randi_range(8, 20):
			put(img, x, y, Color("5f95bd"))
			put(img, x + 1, y, Color(1, 1, 1, 0.45))
			x += dx if rng.randf() < 0.5 else 0
			y += 1 if rng.randf() < 0.8 else 0
			if rng.randf() < 0.2:
				dx = rng.randi_range(-1, 1)
	# Snow drifts.
	for d in int(w * h / 2500.0):
		var cx := rng.randf_range(0, w)
		var cy := rng.randf_range(0, h)
		ellipse(img, cx, cy, rng.randf_range(4, 9), rng.randf_range(2.5, 5), Color(0.96, 0.99, 1.0, 0.9))
		ellipse(img, cx - 1, cy - 1, 2.5, 1.2, Color.WHITE)
	_cache[key] = tex(img)
	return _cache[key]


# ---------- soft lighting helpers ----------

# A round, blurry blob used for shadows: dark in the middle, fading to nothing at the edge.
static func soft_shadow() -> Texture2D:
	if _cache.has("soft_shadow"):
		return _cache["soft_shadow"]
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0, 0, 0, 0.85), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 64
	t.height = 64
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	_cache["soft_shadow"] = t
	return t


# A small soft white dot for particles (leaves, snow, fireflies, dust).
static func soft_dot() -> Texture2D:
	if _cache.has("soft_dot"):
		return _cache["soft_dot"]
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 8
	t.height = 8
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	_cache["soft_dot"] = t
	return t


# ---------- more dungeon floors ----------

# Sandstone blocks for tombs. Origin is the top-left.
static func sandstone_floor(tw: int, th: int) -> Texture2D:
	var key := "sandstone_%d_%d" % [tw, th]
	if _cache.has(key):
		return _cache[key]
	var img := canvas(tw * 16, th * 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 505
	var tones := [Color("c9a86a"), Color("bf9c5e"), Color("d2b377"), Color("b8975a")]
	for ty in th:
		for tx in tw:
			var base: Color = tones[rng.randi() % tones.size()]
			rect(img, tx * 16, ty * 16, 16, 16, base)
			rect(img, tx * 16, ty * 16, 16, 1, base.lightened(0.14))
			rect(img, tx * 16, ty * 16, 1, 16, base.lightened(0.08))
			rect(img, tx * 16, ty * 16 + 15, 16, 1, base.darkened(0.25))
			rect(img, tx * 16 + 15, ty * 16, 1, 16, base.darkened(0.22))
			for i in 5:
				put(img, tx * 16 + rng.randi_range(2, 13), ty * 16 + rng.randi_range(2, 13), base.darkened(0.12) if rng.randf() < 0.5 else base.lightened(0.1))
	# Drifts of sand blown across the floor.
	for d in int(tw * th / 5.0):
		ellipse(img, rng.randf_range(0, tw * 16), rng.randf_range(0, th * 16), rng.randf_range(4, 9), rng.randf_range(2, 4), Color(0.93, 0.82, 0.55, 0.55))
	_cache[key] = tex(img)
	return _cache[key]


# Dark, wet mud with puddles. Origin is the top-left.
static func mud_floor(tw: int, th: int) -> Texture2D:
	var key := "mud_%d_%d" % [tw, th]
	if _cache.has(key):
		return _cache[key]
	var img := canvas(tw * 16, th * 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 606
	for ty in th:
		for tx in tw:
			var base := Color("3a3320") if (tx + ty) % 2 == 0 else Color("42392a")
			rect(img, tx * 16, ty * 16, 16, 16, base)
			for i in 7:
				put(img, tx * 16 + rng.randi_range(0, 15), ty * 16 + rng.randi_range(0, 15), base.lightened(0.12) if rng.randf() < 0.5 else base.darkened(0.2))
	for d in int(tw * th / 4.0):
		var cx := rng.randf_range(0, tw * 16)
		var cy := rng.randf_range(0, th * 16)
		ellipse(img, cx, cy, rng.randf_range(4, 10), rng.randf_range(2.5, 5), Color("27301f"))
		ellipse(img, cx - 1, cy - 1, 2.4, 1.2, Color("5c7050"))
	_cache[key] = tex(img)
	return _cache[key]


# ---------- travel ----------

# A horse and covered wagon. Origin is the bottom-centre of the wagon; 76x40.
static func carriage() -> Texture2D:
	if _cache.has("carriage"):
		return _cache["carriage"]
	var img := canvas(76, 40)
	ellipse(img, 38, 37, 34, 3, Color(0, 0, 0, 0.3))
	var coat := Color("8a5a2b")
	var coat_l := Color("a8743b")
	var coat_d := Color("5a3b1e")
	# Horse: legs, body, neck, head and mane.
	for lx in [6, 10, 18, 22]:
		rect(img, lx, 24, 3, 12, OUT)
		rect(img, lx + 1, 24, 1, 11, coat_d)
	ellipse(img, 15, 22, 12, 7, OUT)
	ellipse(img, 15, 22, 11, 6, coat)
	ellipse(img, 13, 20, 7, 3.5, coat_l)
	rect(img, 22, 12, 6, 12, OUT)
	rect(img, 23, 13, 4, 11, coat)
	ellipse(img, 28, 12, 6, 4.5, OUT)
	ellipse(img, 28, 12, 5, 3.6, coat)
	put(img, 30, 11, OUT)
	rect(img, 22, 11, 3, 9, coat_d)
	rect(img, 2, 18, 4, 3, coat_d)
	rect(img, 0, 20, 3, 8, coat_d)
	# Harness to the wagon.
	rect(img, 27, 24, 12, 2, OUT)
	# Wagon: box, covered hoop, wheels.
	rect(img, 38, 20, 34, 12, OUT)
	rect(img, 39, 21, 32, 10, WOOD_M)
	rect(img, 39, 21, 32, 2, WOOD_L)
	rect(img, 39, 29, 32, 2, WOOD_D)
	ellipse(img, 55, 20, 17, 13, OUT)
	ellipse(img, 55, 20, 16, 12, Color("efe6cc"))
	ellipse(img, 55, 24, 16, 8, Color("efe6cc"))
	rect(img, 38, 20, 34, 12, OUT)
	rect(img, 39, 21, 32, 10, WOOD_M)
	rect(img, 39, 21, 32, 2, WOOD_L)
	for rx in [44, 55, 66]:
		rect(img, rx, 8, 1, 13, Color("c8bd9c"))
	rect(img, 41, 9, 28, 1, Color("f8f1db"))
	rect(img, 54, 14, 3, 4, RED)
	for cx in [46, 66]:
		ellipse(img, cx, 33, 6, 6, OUT)
		ellipse(img, cx, 33, 5, 5, WOOD_L)
		ellipse(img, cx, 33, 2, 2, OUT)
		for a in 4:
			var ang := PI * a / 4.0
			for k in range(-4, 5):
				put(img, cx + roundi(cos(ang) * k), 33 + roundi(sin(ang) * k), WOOD_D)
	_cache["carriage"] = tex(img)
	return _cache["carriage"]
