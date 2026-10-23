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


# The King Slime's treasure chest: purple with gold bands and a slime-green lock. Origin is the
# bottom-centre; 28x26. When open the lid is propped up and the inside shines.
static func royal_chest(open: bool) -> Texture2D:
	var key := "royal_%s" % open
	if _cache.has(key):
		return _cache[key]
	var img := canvas(28, 26)
	var purple := Color("5b3fa0")
	var purple_l := Color("7d5cc9")
	var purple_d := Color("3d2870")
	var green := Color("5de08a")
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
