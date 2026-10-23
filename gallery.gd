extends CanvasLayer
# Dusty's Shooting Gallery: a carnival mini-game. Steer the crosshair with the arrow keys, press
# Space to fire. Bullseyes are worth 5, the inner rings 3 and 1, golden targets 10.

signal finished(score: int)

const PixelArt := preload("res://pixel_art.gd")
const UiStyle := preload("res://ui_style.gd")

const W := 1152.0
const H := 648.0
const ARROWS := 12
const LANE_Y := [210.0, 330.0, 450.0]
const LANE_SPEED := [85.0, 130.0, 175.0]
const LANE_RADIUS := [31.0, 25.0, 20.0]
const CROSS_SPEED := 300.0

var active := false
var targets: Array[Dictionary] = []
var cross := Vector2(W / 2.0, 330.0)
var arrows := ARROWS
var score := 0
var popups: Array = [] # [text, position, time left, colour]
var holes: Array = [] # [position, time left]
var _t := 0.0
var _end_timer := -1.0
var board := Control.new()


func _ready() -> void:
	layer = 8
	visible = false
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.draw.connect(_draw_board)
	add_child(board)


func begin() -> void:
	active = true
	visible = true
	arrows = ARROWS
	score = 0
	popups.clear()
	holes.clear()
	_end_timer = -1.0
	cross = Vector2(W / 2.0, 330.0)
	targets.clear()
	for lane in 3:
		var dir := 1.0 if lane % 2 == 0 else -1.0
		for k in 3:
			targets.append(_make_target(lane, dir, k * 400.0 + lane * 90.0))


func _make_target(lane: int, dir: float, x: float) -> Dictionary:
	var gold := randf() < 0.1
	return {
		"x": x, "y": LANE_Y[lane], "vx": LANE_SPEED[lane] * dir * (1.6 if gold else 1.0),
		"r": LANE_RADIUS[lane] * (0.7 if gold else 1.0), "gold": gold, "lane": lane, "flash": 0.0,
	}


func _aim() -> Vector2:
	# The crosshair drifts a little, like a shaky hand. Time your shots.
	return cross + Vector2(sin(_t * 1.7) * 8.0, cos(_t * 2.3) * 6.0)


func _process(delta: float) -> void:
	if not active:
		return
	_t += delta
	if _end_timer < 0.0:
		var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		cross = (cross + move * CROSS_SPEED * delta).clamp(Vector2(30, 120), Vector2(W - 30, 560))
	for t in targets:
		t.x += t.vx * delta
		t.flash = maxf(t.flash - delta, 0.0)
		if t.vx > 0.0 and t.x > W + t.r:
			_respawn(t, -t.r)
		elif t.vx < 0.0 and t.x < -t.r:
			_respawn(t, W + t.r)
	for p in popups:
		p[1].y -= 40.0 * delta
		p[2] -= delta
	popups = popups.filter(func(p): return p[2] > 0.0)
	for h in holes:
		h[1] -= delta
	holes = holes.filter(func(h): return h[1] > 0.0)
	if _end_timer >= 0.0:
		_end_timer -= delta
		if _end_timer <= 0.0:
			_finish()
	board.queue_redraw()


func _respawn(t: Dictionary, x: float) -> void:
	var dir := signf(t.vx)
	var lane: int = t.lane
	var fresh := _make_target(lane, dir, x)
	for k in fresh:
		t[k] = fresh[k]


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _end_timer < 0.0:
			_shoot()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _end_timer < 0.0:
			arrows = 0
			_end_timer = 0.05


func _shoot() -> void:
	arrows -= 1
	var aim := _aim()
	var best: Dictionary = {}
	var best_d := INF
	for t in targets:
		var d := aim.distance_to(Vector2(t.x, t.y))
		if d <= t.r and d < best_d:
			best = t
			best_d = d
	if best.is_empty():
		holes.append([aim, 3.0])
		popups.append(["miss", aim + Vector2(0, -14), 0.7, Color("c9d1d9")])
	else:
		var ratio: float = best_d / best.r
		var points := 10 if best.gold else (5 if ratio < 0.3 else (3 if ratio < 0.62 else 1))
		score += points
		var label := "+%d" % points
		if points == 5:
			label = "BULLSEYE! +5"
		elif points == 10:
			label = "GOLD! +10"
		popups.append([label, Vector2(best.x, best.y - best.r - 6.0), 1.0, Color("ffd966") if points >= 5 else Color.WHITE])
		best.flash = 0.25
		_respawn(best, -best.r if best.vx > 0.0 else W + best.r)
	if arrows <= 0:
		_end_timer = 1.4


func _finish() -> void:
	active = false
	visible = false
	finished.emit(score)


# ---------- drawing ----------

func _draw_board() -> void:
	# Sky, clouds and rolling hills.
	board.draw_rect(Rect2(0, 0, W, H), Color("86cdf2"))
	board.draw_rect(Rect2(0, 0, W, 170), Color("6fbde8"))
	for i in 4:
		var cx := fposmod(i * 330.0 + _t * 12.0, W + 200.0) - 100.0
		var cy := 130.0 + (i % 2) * 40.0
		board.draw_rect(Rect2(cx, cy, 120, 22), Color("f5fbff"))
		board.draw_rect(Rect2(cx + 18, cy - 14, 70, 20), Color("f5fbff"))
		board.draw_rect(Rect2(cx + 6, cy + 18, 100, 8), Color("d6ecfa"))
	board.draw_rect(Rect2(0, 300, W, 400), Color("7cc86a"))
	for i in 8:
		board.draw_rect(Rect2(i * 170.0 - 40.0, 280.0 + (i % 3) * 14.0, 210, 40), Color("7cc86a"))
	board.draw_rect(Rect2(0, 470, W, 200), Color("58a84a"))

	# Lane rails the targets hang from.
	for lane in 3:
		var y: float = LANE_Y[lane] + LANE_RADIUS[lane] + 6.0
		board.draw_rect(Rect2(0, y, W, 9), Color("2e2233"))
		board.draw_rect(Rect2(0, y + 1, W, 6), Color("8a5a2b"))
		board.draw_rect(Rect2(0, y + 1, W, 2), Color("b07a3c"))

	# Targets.
	for t in targets:
		var tex: Texture2D = PixelArt.target(t.gold)
		var size: float = t.r * 2.0
		var mod := Color.WHITE.lerp(Color(2.5, 2.5, 2.5), t.flash * 4.0)
		board.draw_texture_rect(tex, Rect2(t.x - t.r, t.y - t.r, size, size), false, mod)

	# Arrow holes where shots landed.
	for h in holes:
		var p: Vector2 = h[0]
		board.draw_line(p, p + Vector2(10, -12), Color("5a3b1e"), 3.0)
		board.draw_line(p + Vector2(10, -12), p + Vector2(14, -17), Color("d63c3c"), 3.0)

	# Booth: posts, a striped awning and the title.
	board.draw_rect(Rect2(0, 0, 70, H), Color("5a3b1e"))
	board.draw_rect(Rect2(W - 70, 0, 70, H), Color("5a3b1e"))
	board.draw_rect(Rect2(8, 0, 12, H), Color("8a5a2b"))
	board.draw_rect(Rect2(W - 62, 0, 12, H), Color("8a5a2b"))
	for i in 24:
		var col := Color("d63c3c") if i % 2 == 0 else Color("f5f5f5")
		board.draw_rect(Rect2(i * 48.0, 0, 48, 78), col)
		board.draw_rect(Rect2(i * 48.0, 78, 48, 12), col)
		board.draw_rect(Rect2(i * 48.0 + 8, 90, 32, 8), col)
	board.draw_rect(Rect2(0, 98, W, 4), Color("2e2233"))
	var font := ThemeDB.fallback_font
	board.draw_string_outline(font, Vector2(0, 62), "DUSTY'S SHOOTING GALLERY", HORIZONTAL_ALIGNMENT_CENTER, W, 34, 8, Color("2e2233"))
	board.draw_string(font, Vector2(0, 62), "DUSTY'S SHOOTING GALLERY", HORIZONTAL_ALIGNMENT_CENTER, W, 34, Color("ffd966"))

	# Counter with the remaining arrows and the score.
	board.draw_rect(Rect2(0, 568, W, 80), Color("2e2233"))
	board.draw_rect(Rect2(0, 572, W, 76), Color("8a5a2b"))
	board.draw_rect(Rect2(0, 572, W, 6), Color("b07a3c"))
	for i in arrows:
		var ax := 100.0 + i * 30.0
		board.draw_rect(Rect2(ax, 590, 4, 40), Color("e2c98f"))
		board.draw_rect(Rect2(ax - 3, 586, 10, 8), Color("c9d1d9"))
		board.draw_rect(Rect2(ax - 2, 626, 8, 6), Color("d63c3c"))
	board.draw_string_outline(font, Vector2(W - 380, 624), "SCORE  %d" % score, HORIZONTAL_ALIGNMENT_RIGHT, 320, 38, 8, Color("2e2233"))
	board.draw_string(font, Vector2(W - 380, 624), "SCORE  %d" % score, HORIZONTAL_ALIGNMENT_RIGHT, 320, 38, Color.WHITE)
	board.draw_string_outline(font, Vector2(100, 560), "Arrows to aim, Space to shoot, Esc to stop", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color("2e2233"))
	board.draw_string(font, Vector2(100, 560), "Arrows to aim, Space to shoot, Esc to stop", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

	for p in popups:
		var pos: Vector2 = p[1]
		var c: Color = p[3]
		board.draw_string_outline(font, pos, p[0], HORIZONTAL_ALIGNMENT_CENTER, 200, 26, 6, Color("2e2233"))
		board.draw_string(font, pos - Vector2(0, 0), p[0], HORIZONTAL_ALIGNMENT_CENTER, 200, 26, c)

	if _end_timer < 0.0:
		var a := _aim()
		board.draw_texture_rect(PixelArt.crosshair(), Rect2(a.x - 25, a.y - 25, 51, 51), false)
	else:
		board.draw_string_outline(font, Vector2(0, 340), "ROUND OVER!", HORIZONTAL_ALIGNMENT_CENTER, W, 64, 12, Color("2e2233"))
		board.draw_string(font, Vector2(0, 340), "ROUND OVER!", HORIZONTAL_ALIGNMENT_CENTER, W, 64, Color("ffd966"))
