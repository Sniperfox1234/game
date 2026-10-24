extends RefCounted
# Helpers for the Kenney 12x11 tile sheets (16px tiles, no spacing).

const SIZE := 16
const COLS := 12
const SmoothTexture := preload("res://smooth_texture.gd")

static var _smoothed := {}


# The smoothly upscaled version of a pixel-art sheet. It has the same size and region numbers as the
# original, so sprites made from it just look cleaner.
static func smooth(tex: Texture2D) -> Texture2D:
	var key := tex.resource_path
	if not _smoothed.has(key):
		_smoothed[key] = SmoothTexture.from_image(tex.get_image())
	return _smoothed[key]


static func region(idx: int) -> Rect2:
	return Rect2((idx % COLS) * SIZE, floori(idx / float(COLS)) * SIZE, SIZE, SIZE)


static func sprite(tex: Texture2D, idx: int, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = smooth(tex)
	s.region_enabled = true
	s.region_rect = region(idx)
	s.centered = false
	s.position = pos
	s.region_filter_clip_enabled = true # smooth filtering must not bleed in the neighbouring tile
	return s


static func tileset(tex: Texture2D, total: int = 132) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(SIZE, SIZE)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(SIZE, SIZE)
	for i in total:
		src.create_tile(Vector2i(i % COLS, floori(i / float(COLS))))
	ts.add_source(src, 0)
	return ts
