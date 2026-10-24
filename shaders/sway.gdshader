shader_type canvas_item;
// Wind sway for trees, bushes and flowers: pieces lean and spring back, more toward the top.
// `base` is 0 for a piece standing on the ground and 1 for a piece stacked above another.

uniform float base = 0.0;
uniform float strength = 1.3;
uniform float speed = 1.5;

void vertex() {
	float height = clamp(1.0 - VERTEX.y / 16.0, 0.0, 1.0);
	float h = base + height;
	float phase = MODEL_MATRIX[3].x * 0.045 + MODEL_MATRIX[3].y * 0.03;
	float wave = sin(TIME * speed + phase) + 0.45 * sin(TIME * speed * 2.3 + phase * 1.7);
	VERTEX.x += wave * strength * h * 0.5;
}
