extends Node2D
# 16x16 pixel hero in the same style as the Kenney tiles. Origin is at the feet.
# O outline, S skin, H hair, T shirt, P pants, E eyes.

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

# Set by the player each frame; the sprite only redraws when something visible changes.
var walking := false
var facing_up := false
var _step := 0
var _step_timer := 0.0


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
	if not walking:
		return
	_step_timer += delta
	if _step_timer >= STEP_TIME:
		_step_timer -= STEP_TIME
		_step = (_step + 1) % 4
		queue_redraw()


func _draw() -> void:
	var palette := {
		"O": OUTLINE,
		"E": OUTLINE,
		"S": GameState.skin_color,
		"H": GameState.hair_color,
		"T": GameState.shirt_color,
		"P": PANTS,
	}
	draw_rect(Rect2(-6, -1, 12, 2), Color(0, 0, 0, 0.25))
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
			var yy := y
			var xx := x
			if y >= 14 and walking and _step % 2 == 1:
				# Shift the feet to fake a stride, alternating sides.
				xx += -1 if (x < 8) == (_step == 1) else 1
				xx = clampi(xx, 4, 11)
			var py: float = yy - 16 + (bob if y < 14 else 0)
			draw_rect(Rect2(xx - 8, py, 1, 1), palette[key])
