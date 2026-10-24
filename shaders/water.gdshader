shader_type canvas_item;
// A pond: deeper in the middle, lighter and clearer by the edges, with drifting ripples, caustics
// and glints of sunlight.

uniform vec2 pond_px = vec2(96.0, 64.0);

float hash21(vec2 p) {
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 23.45);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 px = UV * pond_px;
	vec2 to_edge = min(px, pond_px - px);
	float edge = clamp(min(to_edge.x, to_edge.y) / 14.0, 0.0, 1.0);
	vec3 shallow = vec3(0.32, 0.68, 0.76);
	vec3 deep = vec3(0.07, 0.28, 0.50);
	vec3 col = mix(shallow, deep, smoothstep(0.0, 1.0, edge));
	float n1 = vnoise(px * 0.13 + vec2(TIME * 0.20, TIME * 0.12));
	float n2 = vnoise(px * 0.26 - vec2(TIME * 0.17, TIME * 0.22));
	float caustic = smoothstep(0.55, 0.62, abs(n1 - n2) * 2.0 + 0.4) * 0.12;
	col += caustic;
	float ripple = smoothstep(0.76, 0.84, vnoise(vec2(px.x * 0.10, px.y * 0.42) + vec2(TIME * 0.5, TIME * 0.3)));
	col += ripple * 0.2;
	float glint = step(0.9985, hash21(floor(px * 0.55) + floor(TIME * 3.0))) * 0.6;
	col += glint;
	// soft reflection of the sky near the top of the pond
	col = mix(col, vec3(0.75, 0.88, 0.98), 0.12 * smoothstep(0.5, 0.0, UV.y));
	COLOR = vec4(col, 1.0);
}
