shader_type canvas_item;
render_mode blend_add;
// Slow diagonal beams of sunlight drifting across the screen.

uniform float strength = 0.10;
uniform vec3 beam_color = vec3(1.0, 0.92, 0.72);

void fragment() {
	vec2 uv = UV;
	float t = TIME * 0.03;
	float a = uv.x * 1.0 + uv.y * 0.45;
	float beams = 0.0;
	beams += smoothstep(0.55, 1.0, sin(a * 9.0 + t * 3.0) * 0.5 + 0.5) * (sin(a * 3.0 - t * 5.0) * 0.5 + 0.5);
	beams += smoothstep(0.6, 1.0, sin(a * 15.0 - t * 4.0 + 2.0) * 0.5 + 0.5) * 0.5;
	float fade = smoothstep(1.0, 0.1, uv.y) * smoothstep(0.0, 0.3, 1.0 - uv.x + 0.25);
	COLOR = vec4(beam_color * beams * fade * strength, 1.0);
}
