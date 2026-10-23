extends RefCounted
# Helpers for the Kenney 12x11 tile sheets (16px tiles, no spacing).

const SIZE := 16
const COLS := 12


static func region(idx: int) -> Rect2:
	return Rect2((idx % COLS) * SIZE, floori(idx / float(COLS)) * SIZE, SIZE, SIZE)


static func sprite(tex: Texture2D, idx: int, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = region(idx)
	s.centered = false
	s.position = pos
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
