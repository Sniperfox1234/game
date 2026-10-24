extends RefCounted
# Procedural pixel art for the four regions: castle, desert, harbor and swamp.
# Built on the helpers in pixel_art.gd and cached the same way. Origins are noted per piece.

const PA := preload("res://pixel_art.gd")

const OUT := Color("2e2233")
const STONE := Color("a9aab8")
const STONE_L := Color("c9cad6")
const STONE_D := Color("6f7084")
const ROOF := Color("b0392b")
const ROOF_L := Color("d65a47")
const ROOF_D := Color("7a2218")
const WOOD := Color("8a5a2b")
const WOOD_L := Color("b07a3c")
const WOOD_D := Color("5a3b1e")
const GOLD := Color("e8c872")
const GOLD_D := Color("b08a3a")


static func _store(key: String, img: Image) -> Texture2D:
	PA._cache[key] = PA.tex(img)
	return PA._cache[key]


static func _cached(key: String) -> Texture2D:
	return PA._cache.get(key)


# Rows of staggered bricks with a little colour variation and dark mortar.
static func bricks(img: Image, x: int, y: int, w: int, h: int, base: Color, seed_value := 1, bw := 8, bh := 4) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mortar := base.darkened(0.32)
	for row in range(0, h, bh):
		var off := ((row / bh) % 2) * (bw / 2)
		var col := -off
		while col < w:
			var bx := maxi(col, 0)
			var ex := mini(col + bw, w)
			var tone := base.lightened(rng.randf_range(-0.09, 0.1))
			PA.rect(img, x + bx, y + row, ex - bx, mini(bh, h - row), tone)
			PA.rect(img, x + bx, y + row + bh - 1, ex - bx, 1, mortar)
			PA.rect(img, x + ex - 1, y + row, 1, mini(bh, h - row), mortar)
			PA.rect(img, x + bx, y + row, ex - bx, 1, tone.lightened(0.12))
			col += bw


# An arched window; `lit` shows a warm glow inside.
static func window(img: Image, x: int, y: int, w: int, h: int, lit := true) -> void:
	PA.rect(img, x - 1, y - 1, w + 2, h + 1, OUT)
	PA.ellipse(img, x + w / 2.0, y, w / 2.0 + 1.0, w / 2.0 + 1.0, OUT)
	PA.rect(img, x, y, w, h, Color("ffd98a") if lit else Color("3a3a58"))
	PA.ellipse(img, x + w / 2.0, y, w / 2.0, w / 2.0, Color("ffd98a") if lit else Color("3a3a58"))
	PA.rect(img, x + w / 2, y - w / 2, 1, h + w / 2, OUT)
	PA.rect(img, x, y + h / 2, w, 1, OUT)


# A cone roof, `w` wide and `h` tall, drawn into img at (x, y) = its top-left.
static func cone(img: Image, x: int, y: int, w: int, h: int) -> void:
	for row in h:
		var half := (w / 2.0) * (row + 1.0) / h
		var cx := x + w / 2.0
		var left := int(cx - half)
		var width := int(half * 2.0)
		PA.rect(img, left - 1, y + row, width + 2, 1, OUT)
	for row in h:
		var half := (w / 2.0) * (row + 1.0) / h
		var cx := x + w / 2.0
		var left := int(cx - half)
		var width := int(half * 2.0)
		PA.rect(img, left, y + row, width, 1, ROOF)
		PA.rect(img, left, y + row, maxi(width / 3, 1), 1, ROOF_L)
		PA.rect(img, left + width - maxi(width / 4, 1), y + row, maxi(width / 4, 1), 1, ROOF_D)
		if row % 4 == 3:
			PA.rect(img, left, y + row, width, 1, ROOF_D)


# ---------- the castle ----------

# A battlemented wall seen from the front, `tiles` wide, 48px tall. Origin is the top-left.
static func castle_wall(tiles: int) -> Texture2D:
	var key := "c_wall_%d" % tiles
	if _cached(key):
		return _cached(key)
	var w := tiles * 16
	var img := PA.canvas(w, 52)
	# Merlons (the raised teeth along the top).
	for mx in range(0, w, 16):
		PA.rect(img, mx + 2, 0, 12, 12, OUT)
		bricks(img, mx + 3, 1, 10, 11, STONE, mx + 7)
	PA.rect(img, 0, 10, w, 42, OUT)
	bricks(img, 1, 11, w - 2, 40, STONE, 3, 8, 5)
	PA.rect(img, 0, 11, w, 2, STONE_L)
	PA.rect(img, 1, 46, w - 2, 5, STONE_D)
	# Arrow slits.
	for sx in range(24, w - 8, 48):
		PA.rect(img, sx, 22, 3, 12, OUT)
		PA.rect(img, sx - 3, 26, 9, 3, OUT)
	return _store(key, img)


# A thin stretch of side wall seen from above and in front, `tiles` tall, 16 wide. Origin is the top-left.
static func castle_wall_side(tiles: int) -> Texture2D:
	var key := "c_side_%d" % tiles
	if _cached(key):
		return _cached(key)
	var h := tiles * 16
	var img := PA.canvas(20, h)
	PA.rect(img, 0, 0, 20, h, OUT)
	bricks(img, 1, 1, 18, h - 2, STONE_D, 9)
	PA.rect(img, 1, 1, 18, h - 2, Color(1, 1, 1, 0.05))
	for my in range(2, h - 8, 16):
		PA.rect(img, 0, my, 4, 10, OUT)
		PA.rect(img, 1, my + 1, 3, 8, STONE_L)
		PA.rect(img, 16, my, 4, 10, OUT)
		PA.rect(img, 16, my + 1, 3, 8, STONE_L)
	return _store(key, img)


# A round corner tower with arched windows and a red cone roof and flag. Origin is the bottom-centre; 52x120.
static func castle_tower() -> Texture2D:
	if _cached("c_tower"):
		return _cached("c_tower")
	var img := PA.canvas(52, 124)
	PA.ellipse(img, 26, 120, 24, 4, Color(0, 0, 0, 0.3))
	# Body.
	PA.rect(img, 3, 38, 46, 82, OUT)
	bricks(img, 4, 38, 44, 81, STONE, 21, 8, 5)
	PA.rect(img, 4, 38, 10, 81, Color(1, 1, 1, 0.13))
	PA.rect(img, 38, 38, 10, 81, Color(0, 0, 0, 0.18))
	PA.rect(img, 1, 34, 50, 7, OUT)
	PA.rect(img, 2, 35, 48, 5, STONE_D)
	PA.rect(img, 2, 35, 48, 1, STONE_L)
	window(img, 21, 52, 10, 16)
	window(img, 21, 84, 10, 14, false)
	PA.rect(img, 19, 108, 14, 12, OUT)
	PA.ellipse(img, 26, 108, 7, 5, OUT)
	PA.rect(img, 20, 109, 12, 11, WOOD_D)
	# Cone roof and flag.
	cone(img, 0, 4, 52, 32)
	PA.rect(img, 25, 0, 2, 8, WOOD_D)
	PA.rect(img, 27, 0, 9, 5, GOLD)
	PA.rect(img, 27, 4, 9, 1, GOLD_D)
	return _store("c_tower", img)


# The great keep with a central arched door and two side doors, towers, windows and banners.
# Origin is the bottom-centre; 232x168. The three doors sit at x = 48, 116 and 184.
static func castle_keep() -> Texture2D:
	if _cached("c_keep"):
		return _cached("c_keep")
	var img := PA.canvas(232, 168)
	PA.ellipse(img, 116, 165, 112, 5, Color(0, 0, 0, 0.3))
	# Side turrets.
	for tx in [4, 188]:
		PA.rect(img, tx, 52, 40, 112, OUT)
		bricks(img, tx + 1, 52, 38, 111, STONE, tx, 8, 5)
		PA.rect(img, tx + 1, 52, 8, 111, Color(1, 1, 1, 0.12))
		PA.rect(img, tx + 29, 52, 10, 111, Color(0, 0, 0, 0.16))
		cone(img, tx - 2, 14, 44, 40)
		window(img, tx + 15, 76, 10, 16)
		window(img, tx + 15, 112, 10, 14, false)
	# Main hall.
	PA.rect(img, 38, 62, 156, 102, OUT)
	bricks(img, 39, 62, 154, 101, STONE, 77, 8, 5)
	PA.rect(img, 39, 62, 154, 2, STONE_L)
	# Battlements.
	for mx in range(40, 192, 16):
		PA.rect(img, mx, 52, 12, 12, OUT)
		bricks(img, mx + 1, 53, 10, 11, STONE, mx, 5, 3)
	# Upper windows and a rose window.
	for wx in [64, 96, 128, 154]:
		window(img, wx, 88, 10, 16)
	PA.ellipse(img, 116, 78, 9, 9, OUT)
	PA.ellipse(img, 116, 78, 7, 7, Color("e8b03a"))
	PA.ellipse(img, 116, 78, 3, 3, Color("d63c3c"))
	for a in 8:
		var ang := TAU * a / 8.0
		PA.put(img, 116 + roundi(cos(ang) * 6.0), 78 + roundi(sin(ang) * 6.0), OUT)
	# Three arched doors.
	for dx in [48, 116, 184]:
		var big: bool = dx == 116
		var dw := 26 if big else 18
		var dh := 38 if big else 28
		PA.rect(img, dx - dw / 2 - 2, 164 - dh - 2, dw + 4, dh + 2, OUT)
		PA.ellipse(img, dx, 164 - dh, dw / 2.0 + 2.0, dw / 2.0 + 2.0, OUT)
		PA.rect(img, dx - dw / 2, 164 - dh, dw, dh, WOOD_D)
		PA.ellipse(img, dx, 164 - dh, dw / 2.0, dw / 2.0, WOOD_D)
		for p in range(dx - dw / 2 + 3, dx + dw / 2, 5):
			PA.rect(img, p, 164 - dh - 4, 1, dh + 4, WOOD)
		PA.rect(img, dx - 1, 164 - dh - dw / 2, 2, dh + dw / 2, OUT)
		PA.rect(img, dx - 4, 164 - dh / 2, 2, 3, GOLD)
		PA.rect(img, dx + 2, 164 - dh / 2, 2, 3, GOLD)
	# Steps in front of the main door.
	PA.rect(img, 96, 160, 40, 6, OUT)
	PA.rect(img, 98, 161, 36, 4, STONE_L)
	# Royal banners hanging between the doors.
	for bx in [78, 150]:
		PA.rect(img, bx, 112, 14, 40, OUT)
		PA.rect(img, bx + 1, 113, 12, 38, Color("9c2a3a"))
		PA.rect(img, bx + 1, 113, 12, 2, GOLD)
		PA.rect(img, bx + 5, 124, 4, 10, GOLD)
		PA.rect(img, bx + 3, 128, 8, 3, GOLD)
	# The central tower and its flag.
	PA.rect(img, 94, 18, 44, 48, OUT)
	bricks(img, 95, 18, 42, 47, STONE, 5, 8, 5)
	PA.rect(img, 95, 18, 8, 47, Color(1, 1, 1, 0.12))
	cone(img, 90, -2, 52, 22)
	window(img, 111, 36, 10, 14)
	PA.rect(img, 115, 0, 2, 4, WOOD_D)
	PA.rect(img, 117, 0, 10, 5, GOLD)
	return _store("c_keep", img)


# The gatehouse over the south entrance: two squat towers joined by an arch. Origin: bottom-centre; 112x84.
static func castle_gatehouse() -> Texture2D:
	if _cached("c_gate"):
		return _cached("c_gate")
	var img := PA.canvas(112, 84)
	PA.ellipse(img, 56, 81, 52, 4, Color(0, 0, 0, 0.3))
	for tx in [0, 76]:
		PA.rect(img, tx, 14, 36, 68, OUT)
		bricks(img, tx + 1, 14, 34, 67, STONE, tx + 3, 8, 5)
		PA.rect(img, tx + 1, 14, 6, 67, Color(1, 1, 1, 0.12))
		for mx in range(tx + 2, tx + 34, 12):
			PA.rect(img, mx, 4, 9, 12, OUT)
			bricks(img, mx + 1, 5, 7, 11, STONE, mx, 5, 3)
		window(img, tx + 13, 34, 10, 14, false)
		PA.rect(img, tx + 17, 56, 3, 12, OUT)
	# The arch joining them.
	PA.rect(img, 34, 22, 44, 60, OUT)
	bricks(img, 35, 22, 42, 59, STONE, 91, 8, 5)
	PA.rect(img, 34, 18, 44, 6, OUT)
	PA.rect(img, 35, 19, 42, 4, STONE_L)
	PA.ellipse(img, 56, 52, 18, 20, OUT)
	PA.rect(img, 38, 52, 36, 30, OUT)
	PA.ellipse(img, 56, 52, 16, 18, Color("1a1624"))
	PA.rect(img, 40, 52, 32, 29, Color("1a1624"))
	# Raised portcullis teeth, and banners.
	for px in range(42, 72, 5):
		PA.rect(img, px, 36, 2, 7, Color("6f7084"))
	for bx in [30, 76]:
		PA.rect(img, bx, 34, 6, 24, Color("9c2a3a"))
		PA.rect(img, bx, 34, 6, 2, GOLD)
	return _store("c_gate", img)


# A clipped hedge, `tiles` wide. Origin is the top-left; 16*tiles x 20.
static func hedge(tiles: int) -> Texture2D:
	var key := "hedge_%d" % tiles
	if _cached(key):
		return _cached(key)
	var w := tiles * 16
	var img := PA.canvas(w, 20)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	PA.rect(img, 0, 3, w, 17, OUT)
	PA.rect(img, 1, 3, w - 2, 15, Color("2f7a3a"))
	PA.rect(img, 1, 3, w - 2, 4, Color("4faa4c"))
	PA.rect(img, 1, 14, w - 2, 4, Color("205a2a"))
	for i in w * 2:
		var px := rng.randi_range(2, w - 3)
		var py := rng.randi_range(4, 16)
		PA.put(img, px, py, Color("62c05a") if rng.randf() < 0.5 else Color("1d5226"))
	for bx in range(8, w - 6, 18):
		PA.put(img, bx, rng.randi_range(5, 14), Color("e84a5f"))
	return _store(key, img)


# A gilded throne with a red cushion and a crowned back. Origin is the bottom-centre; 36x52.
static func throne() -> Texture2D:
	if _cached("throne"):
		return _cached("throne")
	var img := PA.canvas(36, 52)
	PA.ellipse(img, 18, 49, 16, 3, Color(0, 0, 0, 0.3))
	PA.rect(img, 5, 10, 26, 40, OUT)
	PA.rect(img, 6, 11, 24, 38, GOLD)
	PA.rect(img, 6, 11, 5, 38, GOLD.lightened(0.25))
	PA.rect(img, 25, 11, 5, 38, GOLD_D)
	PA.rect(img, 9, 14, 18, 22, Color("8a1f30"))
	PA.rect(img, 9, 14, 18, 3, Color("b83a4a"))
	# Crown finial and armrests.
	for k in [4, 14, 24]:
		PA.rect(img, k + 3, 2, 6, 10, OUT)
		PA.rect(img, k + 4, 3, 4, 9, GOLD)
	PA.ellipse(img, 18, 5, 3, 3, Color("d63c3c"))
	PA.rect(img, 1, 30, 8, 18, OUT)
	PA.rect(img, 2, 31, 6, 16, GOLD)
	PA.rect(img, 27, 30, 8, 18, OUT)
	PA.rect(img, 28, 31, 6, 16, GOLD_D)
	PA.rect(img, 8, 36, 20, 10, OUT)
	PA.rect(img, 9, 37, 18, 8, Color("a82a3c"))
	return _store("throne", img)


# A long banquet table laid with cloth, plates, goblets, candles and food. Origin is the top-left; 16*tiles x 30.
static func long_table(tiles: int) -> Texture2D:
	var key := "ltable_%d" % tiles
	if _cached(key):
		return _cached(key)
	var w := tiles * 16
	var img := PA.canvas(w, 32)
	PA.rect(img, 0, 6, w, 24, OUT)
	PA.rect(img, 1, 7, w - 2, 20, Color("f1ead8"))
	PA.rect(img, 1, 7, w - 2, 2, Color("ffffff"))
	PA.rect(img, 1, 24, w - 2, 3, Color("b83a4a"))
	for i in range(0, w - 3, 3):
		PA.rect(img, 2 + i, 26, 2, 3, Color("e0d6bc"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for px in range(10, w - 10, 20):
		# A plate with something tasty, and a goblet.
		PA.ellipse(img, px, 17, 7, 3.4, OUT)
		PA.ellipse(img, px, 17, 6, 2.6, Color("f5f5f5"))
		var food: Color = [Color("c9743a"), Color("d6593f"), Color("e8c050"), Color("7bbf4a")][rng.randi() % 4]
		PA.ellipse(img, px, 16, 4, 1.8, food)
		PA.rect(img, px + 9, 12, 4, 7, OUT)
		PA.rect(img, px + 10, 13, 2, 5, GOLD)
	for cx in [w / 4, w * 3 / 4]:
		PA.rect(img, cx, 5, 3, 7, OUT)
		PA.rect(img, cx, 6, 3, 6, Color("fff6d0"))
		PA.rect(img, cx, 2, 3, 4, Color("ff9a3a"))
		PA.put(img, cx + 1, 1, Color("ffe08a"))
	return _store(key, img)


# Two or three stone steps, `tiles` wide, leading up to the throne. Origin is the top-left; 16*tiles x 24.
static func steps(tiles: int) -> Texture2D:
	var key := "steps_%d" % tiles
	if _cached(key):
		return _cached(key)
	var w := tiles * 16
	var img := PA.canvas(w, 24)
	for k in 3:
		var y := k * 8
		PA.rect(img, k * 6, y, w - k * 12, 8, OUT)
		PA.rect(img, k * 6 + 1, y + 1, w - k * 12 - 2, 5, STONE_L.darkened(k * 0.08))
		PA.rect(img, k * 6 + 1, y + 6, w - k * 12 - 2, 1, STONE_D)
	return _store(key, img)


# ---------- desert ----------

const SAND_D := Color("c99a4e")
const SAND_L := Color("f0d890")
const SANDSTONE := Color("d9b36a")
const SANDSTONE_L := Color("ecd08e")
const SANDSTONE_D := Color("a37a3c")


# A triangle of stacked rows, widest at the bottom. Used for pyramids and tent roofs.
static func _tri(img: Image, cx: int, top: int, base_y: int, half_w: int, c: Color) -> void:
	var h := base_y - top
	for y in range(top, base_y):
		var t := float(y - top) / maxf(h - 1, 1)
		var hw := int(round(half_w * t))
		PA.rect(img, cx - hw, y, hw * 2 + 1, 1, c)


# A stepped sandstone pyramid with a dark doorway. Origin is the bottom-centre; 176x112.
# The doorway is at x = 88, the bottom 22 px of the picture.
static func pyramid() -> Texture2D:
	if _cached("pyramid"):
		return _cached("pyramid")
	var img := PA.canvas(176, 112)
	PA.ellipse(img, 88, 108, 84, 5, Color(0, 0, 0, 0.28))
	_tri(img, 88, 2, 110, 86, OUT)
	_tri(img, 88, 4, 109, 84, SANDSTONE)
	# Light face on the left, shaded face on the right, and courses of blocks.
	for y in range(4, 109):
		var t := float(y - 4) / 104.0
		var hw := int(round(84 * t))
		PA.rect(img, 88 + hw - maxi(hw / 2, 1), y, maxi(hw / 2, 1) + 1, 1, SANDSTONE_D)
		PA.rect(img, 88 - hw, y, maxi(hw / 4, 1), 1, SANDSTONE_L)
		if y % 9 == 0:
			PA.rect(img, 88 - hw + 1, y, hw * 2 - 1, 1, SANDSTONE_D)
	PA.rect(img, 86, 0, 5, 5, GOLD)
	PA.rect(img, 86, 0, 5, 1, Color("fff0b0"))
	# Doorway.
	PA.rect(img, 76, 86, 24, 24, OUT)
	PA.rect(img, 78, 88, 20, 22, Color("120d18"))
	PA.rect(img, 74, 84, 28, 3, SANDSTONE_L)
	PA.rect(img, 74, 84, 3, 26, SANDSTONE_D)
	PA.rect(img, 99, 84, 3, 26, SANDSTONE_D)
	return _store("pyramid", img)


# A palm tree. Origin is the bottom-centre; 44x72.
static func palm() -> Texture2D:
	if _cached("palm"):
		return _cached("palm")
	var img := PA.canvas(44, 72)
	PA.ellipse(img, 22, 68, 10, 3, Color(0, 0, 0, 0.25))
	for i in 16:
		var x := 21 + int(round(sin(i * 0.2) * 3.0))
		PA.rect(img, x, 24 + i * 3, 5, 4, OUT)
		PA.rect(img, x + 1, 24 + i * 3, 3, 4, Color("9a6a3a") if i % 2 == 0 else Color("b2824a"))
	var green := Color("3f9a4a")
	var green_l := Color("6fc25a")
	for a in [-2.6, -2.0, -1.3, -0.5, 0.2, 0.9]:
		var dir := Vector2(cos(a), sin(a) * 0.55 - 0.1)
		for s in 15:
			var p := Vector2(24, 26) + dir * s * 1.5 + Vector2(0, s * s * 0.045)
			PA.rect(img, int(p.x) - 1, int(p.y) - 1, 4, 3, OUT if s == 14 else green)
			PA.rect(img, int(p.x), int(p.y) - 1, 2, 1, green_l)
	PA.ellipse(img, 24, 28, 3, 3, Color("7a4a22"))
	return _store("palm", img)


# A saguaro-style cactus. Origin is the bottom-centre; 20x34.
static func cactus() -> Texture2D:
	if _cached("cactus"):
		return _cached("cactus")
	var img := PA.canvas(20, 34)
	PA.ellipse(img, 10, 31, 8, 2.5, Color(0, 0, 0, 0.25))
	var g := Color("4a9a52")
	PA.rect(img, 7, 3, 7, 30, OUT)
	PA.rect(img, 8, 4, 5, 29, g)
	PA.rect(img, 8, 4, 2, 29, Color("78c47a"))
	PA.rect(img, 1, 12, 7, 5, OUT)
	PA.rect(img, 2, 13, 5, 3, g)
	PA.rect(img, 1, 6, 4, 10, OUT)
	PA.rect(img, 2, 7, 2, 9, g)
	PA.rect(img, 13, 16, 6, 5, OUT)
	PA.rect(img, 13, 17, 5, 3, g)
	PA.rect(img, 16, 10, 4, 10, OUT)
	PA.rect(img, 16, 11, 2, 9, g)
	return _store("cactus", img)


# A merchant's striped tent. Origin is the bottom-centre; 72x56.
static func tent(c1: Color, c2: Color) -> Texture2D:
	var key := "tent_%s_%s" % [c1.to_html(false), c2.to_html(false)]
	if _cached(key):
		return _cached(key)
	var img := PA.canvas(72, 56)
	PA.ellipse(img, 36, 53, 34, 4, Color(0, 0, 0, 0.25))
	_tri(img, 36, 2, 52, 34, OUT)
	_tri(img, 36, 4, 51, 32, c1)
	for x in range(-32, 33, 16):
		for y in range(4, 51):
			var t := float(y - 4) / 47.0
			var hw := int(round(32 * t))
			var px := 36 + int(round(x * t))
			if absi(x) <= hw:
				PA.rect(img, px, y, int(round(8 * t)) + 1, 1, c2)
	PA.rect(img, 28, 36, 16, 16, OUT)
	PA.rect(img, 29, 37, 14, 15, Color("3a1f14"))
	PA.rect(img, 35, 0, 2, 6, WOOD_D)
	PA.rect(img, 37, 0, 8, 4, c2)
	return _store(key, img)


# A standing or broken sandstone pillar. Origin is the bottom-centre; 22x56.
static func ruin_pillar(broken: bool) -> Texture2D:
	var key := "ruin_%s" % broken
	if _cached(key):
		return _cached(key)
	var img := PA.canvas(22, 56)
	PA.ellipse(img, 11, 53, 10, 3, Color(0, 0, 0, 0.25))
	var top := 22 if broken else 6
	PA.rect(img, 2, 46, 18, 8, OUT)
	PA.rect(img, 3, 47, 16, 6, SANDSTONE_D)
	PA.rect(img, 4, top, 14, 46 - top, OUT)
	PA.rect(img, 5, top, 12, 46 - top, SANDSTONE)
	PA.rect(img, 5, top, 3, 46 - top, SANDSTONE_L)
	PA.rect(img, 14, top, 3, 46 - top, SANDSTONE_D)
	for y in range(top + 6, 46, 9):
		PA.rect(img, 5, y, 12, 1, SANDSTONE_D)
	if not broken:
		PA.rect(img, 1, 2, 20, 6, OUT)
		PA.rect(img, 2, 3, 18, 4, SANDSTONE_L)
	else:
		for x in range(5, 17, 3):
			PA.rect(img, x, top - 2 + (x % 4), 3, 3, SANDSTONE_D)
	return _store(key, img)


# A tall carved obelisk. Origin is the bottom-centre; 20x70.
static func obelisk() -> Texture2D:
	if _cached("obelisk"):
		return _cached("obelisk")
	var img := PA.canvas(20, 70)
	PA.ellipse(img, 10, 67, 9, 3, Color(0, 0, 0, 0.25))
	PA.rect(img, 2, 58, 16, 9, OUT)
	PA.rect(img, 3, 59, 14, 7, SANDSTONE_D)
	for y in range(12, 58):
		var hw := 4 + (y - 12) / 9
		PA.rect(img, 10 - hw - 1, y, hw * 2 + 2, 1, OUT)
		PA.rect(img, 10 - hw, y, hw * 2, 1, SANDSTONE)
		PA.rect(img, 10 - hw, y, 2, 1, SANDSTONE_L)
		PA.rect(img, 10 + hw - 3, y, 3, 1, SANDSTONE_D)
	_tri(img, 10, 4, 13, 5, OUT)
	_tri(img, 10, 5, 13, 4, GOLD)
	for y in range(20, 54, 7):
		PA.rect(img, 8, y, 4, 2, SANDSTONE_D)
	return _store("obelisk", img)


# ---------- harbor ----------

# A wooden sailing ship moored sideways. Origin is the bottom-centre; 136x120.
static func ship() -> Texture2D:
	if _cached("ship"):
		return _cached("ship")
	var img := PA.canvas(136, 120)
	PA.ellipse(img, 68, 108, 62, 7, Color(0, 0, 0, 0.22))
	# Hull.
	for y in 20:
		var inset := int(pow(float(y) / 19.0, 2.0) * 16.0)
		PA.rect(img, 4 + inset, 84 + y, 128 - inset * 2, 1, OUT)
		PA.rect(img, 5 + inset, 84 + y, 126 - inset * 2, 1, Color("7a4a24") if y % 6 != 5 else Color("4a2c14"))
	PA.rect(img, 4, 80, 128, 5, OUT)
	PA.rect(img, 5, 81, 126, 3, Color("b2824a"))
	PA.rect(img, 5, 81, 126, 1, Color("d8a868"))
	for x in range(14, 126, 18):
		PA.ellipse(img, x, 94, 3, 3, OUT)
		PA.ellipse(img, x, 94, 1.5, 1.5, Color("3a3a48"))
	# Masts, sails and flag.
	for mx in [40, 92]:
		PA.rect(img, mx - 2, 14, 5, 68, OUT)
		PA.rect(img, mx - 1, 14, 3, 68, WOOD)
		PA.rect(img, mx - 22, 18, 46, 3, OUT)
		for y in range(22, 62):
			var w := 20 + int(sin((y - 22) / 40.0 * PI) * 5.0)
			PA.rect(img, mx - w - 1, y, w * 2 + 3, 1, OUT)
			PA.rect(img, mx - w, y, w * 2 + 1, 1, Color("f4ecd8") if y % 11 != 0 else Color("d8cdb0"))
	PA.rect(img, 92, 2, 14, 9, Color("1a1a24"))
	PA.rect(img, 96, 4, 4, 4, Color("f4f4f4"))
	return _store("ship", img)


# A tall striped lighthouse with a lamp room. Origin is the bottom-centre; 44x132.
static func lighthouse() -> Texture2D:
	if _cached("lighthouse"):
		return _cached("lighthouse")
	var img := PA.canvas(44, 132)
	PA.ellipse(img, 22, 128, 20, 4, Color(0, 0, 0, 0.3))
	for y in range(34, 126):
		var hw := 10 + (y - 34) / 11
		PA.rect(img, 22 - hw - 1, y, hw * 2 + 3, 1, OUT)
		var band := ((y - 34) / 14) % 2 == 0
		var base := Color("f2eee4") if band else Color("c84a3a")
		PA.rect(img, 22 - hw, y, hw * 2 + 1, 1, base)
		PA.rect(img, 22 - hw, y, 3, 1, base.lightened(0.15))
		PA.rect(img, 22 + hw - 3, y, 4, 1, base.darkened(0.2))
	PA.rect(img, 12, 30, 20, 5, OUT)
	PA.rect(img, 13, 31, 18, 3, STONE_L)
	PA.rect(img, 15, 14, 14, 17, OUT)
	PA.rect(img, 16, 15, 12, 15, Color("ffe8a0"))
	PA.rect(img, 21, 15, 2, 15, OUT)
	_tri(img, 22, 2, 15, 10, OUT)
	_tri(img, 22, 3, 15, 8, Color("c84a3a"))
	PA.rect(img, 18, 108, 8, 17, OUT)
	PA.rect(img, 19, 109, 6, 16, WOOD_D)
	PA.rect(img, 17, 60, 10, 4, OUT)
	PA.rect(img, 19, 61, 6, 2, Color("ffe8a0"))
	return _store("lighthouse", img)


# A stack of crates and a barrel. Origin is the bottom-centre; 36x32.
static func crates() -> Texture2D:
	if _cached("crates"):
		return _cached("crates")
	var img := PA.canvas(36, 32)
	PA.ellipse(img, 18, 29, 17, 3, Color(0, 0, 0, 0.25))
	for r in [Rect2i(2, 14, 16, 15), Rect2i(18, 18, 14, 11), Rect2i(6, 2, 14, 13)]:
		PA.rect(img, r.position.x, r.position.y, r.size.x, r.size.y, OUT)
		PA.rect(img, r.position.x + 1, r.position.y + 1, r.size.x - 2, r.size.y - 2, WOOD_L)
		PA.rect(img, r.position.x + 1, r.position.y + 1, r.size.x - 2, 2, Color("d8a868"))
		PA.rect(img, r.position.x + r.size.x / 2, r.position.y + 1, 1, r.size.y - 2, WOOD_D)
		PA.rect(img, r.position.x + 1, r.position.y + r.size.y / 2, r.size.x - 2, 1, WOOD_D)
	return _store("crates", img)


# A little rowing boat tied to the dock. Origin is the bottom-centre; 48x24.
static func rowboat() -> Texture2D:
	if _cached("rowboat"):
		return _cached("rowboat")
	var img := PA.canvas(48, 24)
	PA.ellipse(img, 24, 20, 22, 3, Color(0, 0, 0, 0.2))
	for y in 10:
		var inset := int(pow(float(y) / 9.0, 2.0) * 7.0)
		PA.rect(img, 2 + inset, 8 + y, 44 - inset * 2, 1, OUT)
		PA.rect(img, 3 + inset, 8 + y, 42 - inset * 2, 1, Color("9a6a3a") if y % 4 != 3 else Color("6a4220"))
	PA.rect(img, 2, 6, 44, 3, OUT)
	PA.rect(img, 3, 7, 42, 1, Color("d8a868"))
	PA.rect(img, 20, 4, 14, 3, WOOD_D)
	return _store("rowboat", img)


# A rock arch with a dark opening: the way into the pirate cove. Origin is the bottom-centre; 72x56.
# `tint` colours the stone; the doorway is the middle 20 px.
static func cave_arch(tint: Color) -> Texture2D:
	var key := "arch_%s" % tint.to_html(false)
	if _cached(key):
		return _cached(key)
	var img := PA.canvas(72, 56)
	PA.ellipse(img, 36, 53, 34, 4, Color(0, 0, 0, 0.3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for y in range(6, 54):
		var t := float(y - 6) / 47.0
		var hw := int(round(18.0 + 16.0 * sqrt(t)))
		PA.rect(img, 36 - hw - 1, y, hw * 2 + 3, 1, OUT)
		for x in range(36 - hw, 36 + hw + 1):
			var n := 0.9 + rng.randf() * 0.22
			PA.put(img, x, y, Color(tint.r * n, tint.g * n, tint.b * n))
	PA.rect(img, 26, 28, 20, 26, OUT)
	PA.ellipse(img, 36, 30, 10, 8, OUT)
	PA.rect(img, 27, 30, 18, 24, Color("0c0912"))
	PA.ellipse(img, 36, 31, 9, 7, Color("0c0912"))
	PA.rect(img, 10, 10, 14, 4, Color(1, 1, 1, 0.12))
	return _store(key, img)


# ---------- swamp ----------

# A gnarled leafless tree with a hollow. Origin is the bottom-centre; 52x76.
static func dead_tree() -> Texture2D:
	if _cached("dead_tree"):
		return _cached("dead_tree")
	var img := PA.canvas(52, 76)
	PA.ellipse(img, 26, 72, 18, 4, Color(0, 0, 0, 0.28))
	var bark := Color("5a4a40")
	for y in range(30, 72):
		var w := 7 + (y - 30) / 10
		var sway := int(sin(y * 0.18) * 2.0)
		PA.rect(img, 26 - w - 1 + sway, y, w * 2 + 3, 1, OUT)
		PA.rect(img, 26 - w + sway, y, w * 2 + 1, 1, bark)
		PA.rect(img, 26 - w + sway, y, 3, 1, bark.lightened(0.15))
	PA.ellipse(img, 26, 56, 4, 6, OUT)
	# Branches.
	for b in [Vector3(-1, 36, 20), Vector3(1, 32, 22), Vector3(-1, 22, 14), Vector3(1, 18, 12)]:
		var dir := int(b.x)
		for s in int(b.z):
			var x := 26 + dir * (s + 4)
			var y := int(b.y) - s * 7 / 10
			PA.rect(img, x, y, 3, 3, OUT)
			PA.rect(img, x, y, 2, 2, bark)
	return _store("dead_tree", img)


# The witch's hut on stilts with a mossy thatched roof and a green window. Origin is the bottom-centre; 88x88.
static func witch_hut() -> Texture2D:
	if _cached("witch_hut"):
		return _cached("witch_hut")
	var img := PA.canvas(88, 88)
	PA.ellipse(img, 44, 84, 40, 4, Color(0, 0, 0, 0.3))
	for x in [14, 36, 58, 76]:
		PA.rect(img, x, 62, 4, 22, OUT)
		PA.rect(img, x + 1, 62, 2, 22, WOOD_D)
	PA.rect(img, 6, 34, 76, 30, OUT)
	PA.rect(img, 8, 36, 72, 26, Color("6a5236"))
	for x in range(8, 80, 8):
		PA.rect(img, x, 36, 1, 26, Color("4a3a24"))
	PA.rect(img, 52, 42, 14, 14, OUT)
	PA.rect(img, 53, 43, 12, 12, Color("7dff7a"))
	PA.rect(img, 58, 43, 2, 12, OUT)
	PA.rect(img, 18, 44, 14, 20, OUT)
	PA.rect(img, 19, 45, 12, 19, Color("2a1c14"))
	_tri(img, 44, 2, 38, 44, OUT)
	_tri(img, 44, 4, 37, 42, Color("5f7a3a"))
	for y in range(8, 36, 5):
		PA.rect(img, 44 - (y - 4) * 42 / 33, y, ((y - 4) * 42 / 33) * 2, 1, Color("3e5a26"))
	PA.rect(img, 70, 4, 7, 20, OUT)
	PA.rect(img, 71, 5, 5, 19, STONE_D)
	return _store("witch_hut", img)


# A cluster of huge glowing mushrooms. Origin is the bottom-centre; 36x32.
static func big_mushrooms() -> Texture2D:
	if _cached("big_mushrooms"):
		return _cached("big_mushrooms")
	var img := PA.canvas(36, 32)
	PA.ellipse(img, 18, 29, 16, 3, Color(0, 0, 0, 0.25))
	for m in [Vector3(10, 18, 8), Vector3(24, 22, 6), Vector3(17, 12, 7)]:
		var cx := int(m.x)
		var top := int(m.y)
		PA.rect(img, cx - 2, top + 4, 5, 28 - top - 4, OUT)
		PA.rect(img, cx - 1, top + 4, 3, 28 - top - 4, Color("e8e0c8"))
		PA.ellipse(img, cx, top, m.z + 1, m.z * 0.65 + 1, OUT)
		PA.ellipse(img, cx, top, m.z, m.z * 0.65, Color("a050e0"))
		PA.rect(img, cx - 3, top - 2, 2, 2, Color("e8c8ff"))
		PA.rect(img, cx + 2, top, 2, 2, Color("e8c8ff"))
	return _store("big_mushrooms", img)


# A weathered gravestone. Origin is the bottom-centre; 18x26.
static func gravestone() -> Texture2D:
	if _cached("gravestone"):
		return _cached("gravestone")
	var img := PA.canvas(18, 26)
	PA.ellipse(img, 9, 23, 8, 2.5, Color(0, 0, 0, 0.28))
	PA.rect(img, 2, 8, 14, 16, OUT)
	PA.ellipse(img, 9, 8, 7, 6, OUT)
	PA.rect(img, 3, 9, 12, 14, Color("8a8f8a"))
	PA.ellipse(img, 9, 8, 6, 5, Color("8a8f8a"))
	PA.rect(img, 3, 9, 3, 14, Color("a8aea8"))
	PA.rect(img, 8, 6, 2, 8, OUT)
	PA.rect(img, 6, 8, 6, 2, OUT)
	PA.rect(img, 3, 20, 12, 3, Color("4f7a40"))
	return _store("gravestone", img)


# A tuft of reeds with cattails. Origin is the bottom-centre; 18x30.
static func reeds() -> Texture2D:
	if _cached("reeds"):
		return _cached("reeds")
	var img := PA.canvas(18, 30)
	for x in [3, 7, 11, 14]:
		PA.rect(img, x, 8 + x % 5, 2, 20 - x % 5, OUT)
		PA.rect(img, x, 9 + x % 5, 1, 19 - x % 5, Color("7aa04a"))
	for x in [7, 14]:
		PA.rect(img, x - 1, 3 + x % 4, 4, 8, OUT)
		PA.rect(img, x, 4 + x % 4, 2, 6, Color("7a4a2a"))
	return _store("reeds", img)
