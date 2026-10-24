extends Texture2D
# Pixel art that doesn't look like blocks. To the rest of the game this is an ordinary small texture
# (same size, same region numbers), but it draws from a copy that was smoothly upscaled 4x, so the
# stair-stepped edges of the pixel art come out as clean, rounded curves.

const FACTOR := 4

var _big: Texture2D
var _w := 1
var _h := 1


static func from_image(img: Image) -> Texture2D:
	var t = new()
	t._setup(img)
	return t


func _setup(img: Image) -> void:
	_w = img.get_width()
	_h = img.get_height()
	var big := img.duplicate() as Image
	if big.get_format() != Image.FORMAT_RGBA8:
		big.convert(Image.FORMAT_RGBA8)
	big.fix_alpha_edges() # so the transparent border doesn't darken the outlines
	big.resize(_w * FACTOR, _h * FACTOR, Image.INTERPOLATE_CUBIC)
	_big = ImageTexture.create_from_image(big)


func _get_width() -> int:
	return _w


func _get_height() -> int:
	return _h


func _has_alpha() -> bool:
	return true


func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect(to_canvas_item, Rect2(pos, Vector2(_w, _h)), _big.get_rid(), false, modulate, transpose)


func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect(to_canvas_item, rect, _big.get_rid(), tile, modulate, transpose)


func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	var src := Rect2(src_rect.position * FACTOR, src_rect.size * FACTOR)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, rect, _big.get_rid(), src, modulate, transpose, clip_uv)
