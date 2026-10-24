shader_type canvas_item;
// Paints a whole map's ground smoothly from a tiny "type map" (one pixel per tile). Neighbouring
// terrain types melt into each other along wobbly, natural edges instead of sitting on a tile grid.
//   0 grass  1 dirt path  2 cobblestone  3 sand  4 tilled soil  5 flagstone  6 snow  7 mud
//   8 swamp grass  9 water  10 dry scrub  11 wooden planks  12 courtyard stone

uniform sampler2D types : filter_nearest, repeat_disable;
uniform ivec2 map_tiles = ivec2(40, 28);

float hash21(vec2 p) {
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 23.45);
	return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
	float n = hash21(p);
	return vec2(n, hash21(p + n + 17.0));
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

int tile_at(ivec2 c) {
	c = clamp(c, ivec2(0), map_tiles - ivec2(1));
	return int(texelFetch(types, c, 0).r * 255.0 + 0.5);
}

bool is_hard(int t) {
	return t == 2 || t == 5 || t == 11 || t == 12;
}

vec3 grass_color(vec2 p, vec3 dark, vec3 light, vec3 dry_col, float flowers) {
	float big = fbm(p * 0.35);
	vec3 col = mix(dark, light, big);
	float dry = smoothstep(0.55, 0.85, fbm(p * 0.13 + 7.0));
	col = mix(col, dry_col, dry * 0.35);
	col *= 0.90 + 0.20 * vnoise(p * 9.0);
	vec2 g = p * 4.5;
	vec2 cell = floor(g);
	vec2 f = fract(g) - 0.5;
	vec2 jitter = (hash22(cell) - 0.5) * 0.5;
	float tuft = smoothstep(0.26, 0.0, length(f - jitter)) * step(0.78, hash21(cell));
	col *= 1.0 - 0.28 * tuft;
	col += 0.05 * smoothstep(0.7, 1.0, vnoise(p * vec2(14.0, 22.0)));
	if (flowers > 0.0) {
		vec2 fg = p * 2.6;
		vec2 fc = floor(fg);
		vec2 ff = fract(fg) - 0.5;
		if (hash21(fc + 11.0) > 1.0 - 0.085 * flowers) {
			vec2 off = (hash22(fc + 3.0) - 0.5) * 0.5;
			float d = length(ff - off);
			float pick = hash21(fc + 5.0);
			vec3 fcol = pick < 0.35 ? vec3(0.98, 0.97, 0.90) : (pick < 0.65 ? vec3(0.98, 0.82, 0.25) : (pick < 0.85 ? vec3(0.95, 0.50, 0.62) : vec3(0.62, 0.52, 0.95)));
			col = mix(col, fcol, smoothstep(0.075, 0.045, d));
			col = mix(col, vec3(0.95, 0.70, 0.15), smoothstep(0.025, 0.012, d));
		}
	}
	return col;
}

vec3 path_color(vec2 p) {
	vec3 col = mix(vec3(0.60, 0.44, 0.27), vec3(0.74, 0.58, 0.37), fbm(p * 0.6));
	col *= 0.92 + 0.16 * vnoise(p * 8.0);
	// pebbles
	vec2 g = p * 3.2;
	vec2 cell = floor(g);
	vec2 f = fract(g) - 0.5;
	vec2 jitter = (hash22(cell) - 0.5) * 0.6;
	float peb = smoothstep(0.11, 0.07, length(f - jitter)) * step(0.72, hash21(cell + 4.0));
	col = mix(col, vec3(0.78, 0.74, 0.68) * (0.85 + 0.3 * hash21(cell)), peb);
	// wheel ruts
	col *= 1.0 - 0.07 * smoothstep(0.5, 0.9, fbm(p * vec2(0.9, 5.0)));
	return col;
}

vec3 stone_slabs(vec2 p, float scale, vec3 base_a, vec3 base_b, vec3 mortar) {
	vec2 s = p * scale;
	s.x += floor(s.y) * 0.5;
	vec2 cell = floor(s);
	vec2 f = fract(s);
	float h = hash21(cell);
	vec3 col = mix(base_a, base_b, h);
	col *= 0.93 + 0.14 * fbm(p * 5.0);
	// bevel: lighter on the top-left edge, darker bottom-right
	float edge_l = smoothstep(0.0, 0.12, min(f.x, f.y));
	float edge_d = smoothstep(0.0, 0.12, min(1.0 - f.x, 1.0 - f.y));
	col *= 0.80 + 0.2 * edge_l;
	col *= 0.86 + 0.14 * edge_d;
	float joint = 1.0 - smoothstep(0.0, 0.07, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)));
	col = mix(col, mortar, joint * 0.85);
	// hairline cracks
	col *= 1.0 - 0.18 * smoothstep(0.93, 1.0, vnoise(p * 3.1 + cell));
	return col;
}

vec3 sand_color(vec2 p) {
	vec3 col = mix(vec3(0.84, 0.72, 0.47), vec3(0.93, 0.83, 0.60), fbm(p * 0.5));
	float ripple = sin((p.x * 2.4 + p.y * 1.1 + fbm(p * 0.8) * 7.0) * 3.14159);
	col *= 0.96 + 0.05 * ripple;
	col *= 0.95 + 0.1 * vnoise(p * 11.0);
	col += 0.04 * smoothstep(0.9, 1.0, vnoise(p * 22.0));
	return col;
}

vec3 soil_color(vec2 p) {
	vec3 col = mix(vec3(0.36, 0.24, 0.14), vec3(0.48, 0.33, 0.20), fbm(p * 1.3));
	float furrow = sin(p.y * 6.28318 * 2.0);
	col *= 0.86 + 0.14 * furrow;
	col *= 0.92 + 0.16 * vnoise(p * 10.0);
	col += 0.05 * smoothstep(0.85, 1.0, vnoise(p * 18.0));
	return col;
}

vec3 snow_color(vec2 p, float time) {
	vec3 col = mix(vec3(0.86, 0.92, 0.99), vec3(0.98, 0.99, 1.0), fbm(p * 0.7));
	col = mix(col, vec3(0.74, 0.84, 0.96), 0.4 * smoothstep(0.55, 0.85, fbm(p * 1.6 + 4.0)));
	float sparkle = step(0.985, hash21(floor(p * 18.0))) * (0.5 + 0.5 * sin(time * 3.0 + hash21(floor(p * 18.0)) * 30.0));
	return col + sparkle * 0.3;
}

vec3 mud_color(vec2 p) {
	vec3 col = mix(vec3(0.22, 0.19, 0.11), vec3(0.34, 0.28, 0.16), fbm(p * 0.9));
	col *= 0.90 + 0.2 * vnoise(p * 7.0);
	float wet = smoothstep(0.6, 0.75, fbm(p * 1.4 + 2.0));
	col = mix(col, vec3(0.15, 0.16, 0.12), wet * 0.6);
	col += wet * 0.06 * smoothstep(0.8, 1.0, vnoise(p * 12.0));
	return col;
}

vec3 planks_color(vec2 p) {
	vec2 s = vec2(p.x * 0.6, p.y * 3.0);
	float row = floor(s.y);
	s.x += hash21(vec2(row, 3.0)) * 5.0;
	vec2 cell = vec2(floor(s.x), row);
	vec2 f = fract(s);
	vec3 col = mix(vec3(0.46, 0.31, 0.17), vec3(0.62, 0.44, 0.25), hash21(cell));
	col *= 0.9 + 0.2 * vnoise(vec2(p.x * 1.5, p.y * 26.0));
	col *= 0.80 + 0.2 * smoothstep(0.0, 0.14, f.y) * smoothstep(0.0, 0.14, 1.0 - f.y);
	float nail = smoothstep(0.09, 0.05, length(vec2(f.x - 0.5, f.y - 0.5)));
	return mix(col, vec3(0.22, 0.17, 0.12), nail * 0.0);
}

vec3 water_color(vec2 p, float time) {
	vec3 deep = vec3(0.07, 0.30, 0.52);
	vec3 shallow = vec3(0.20, 0.55, 0.72);
	float depth = fbm(p * 0.4 + vec2(time * 0.02, 0.0));
	vec3 col = mix(deep, shallow, depth);
	float w1 = vnoise(p * vec2(1.3, 5.0) + vec2(time * 0.35, time * 0.6));
	float w2 = vnoise(p * vec2(2.4, 9.0) + vec2(-time * 0.5, time * 0.9));
	float waves = smoothstep(0.72, 0.8, w1) * 0.35 + smoothstep(0.78, 0.84, w2) * 0.25;
	col += waves;
	float glint = step(0.998, hash21(floor(p * 14.0 + floor(time * 2.0)))) * 0.5;
	return col + glint;
}

vec3 terrain(int t, vec2 p, float time) {
	if (t == 0) return grass_color(p, vec3(0.22, 0.48, 0.16), vec3(0.40, 0.66, 0.24), vec3(0.55, 0.62, 0.27), 1.0);
	if (t == 1) return path_color(p);
	if (t == 2) return stone_slabs(p, 1.6, vec3(0.58, 0.60, 0.65), vec3(0.72, 0.74, 0.78), vec3(0.32, 0.34, 0.38));
	if (t == 3) return sand_color(p);
	if (t == 4) return soil_color(p);
	if (t == 5) return stone_slabs(p, 1.0, vec3(0.46, 0.48, 0.55), vec3(0.62, 0.64, 0.70), vec3(0.22, 0.23, 0.28));
	if (t == 6) return snow_color(p, time);
	if (t == 7) return mud_color(p);
	if (t == 8) return grass_color(p, vec3(0.13, 0.27, 0.14), vec3(0.24, 0.42, 0.20), vec3(0.34, 0.38, 0.16), 0.0);
	if (t == 9) return water_color(p, time);
	if (t == 10) return grass_color(p, vec3(0.50, 0.46, 0.22), vec3(0.70, 0.64, 0.34), vec3(0.78, 0.66, 0.36), 0.0);
	if (t == 11) return planks_color(p);
	return stone_slabs(p, 1.0, vec3(0.64, 0.60, 0.54), vec3(0.78, 0.74, 0.66), vec3(0.36, 0.33, 0.30));
}

void fragment() {
	vec2 q = UV * vec2(map_tiles);
	ivec2 c0 = ivec2(floor(q - 0.5));
	bool hard = is_hard(tile_at(c0)) || is_hard(tile_at(c0 + ivec2(1, 0))) || is_hard(tile_at(c0 + ivec2(0, 1))) || is_hard(tile_at(c0 + ivec2(1, 1)));
	float wobble = hard ? 0.07 : 0.45;
	vec2 d = (vec2(fbm(q * 1.7 + 3.0), fbm(q * 1.7 + 19.0)) - 0.5) * 2.0 * wobble;
	vec2 qd = q + d;
	ivec2 c = ivec2(floor(qd - 0.5));
	vec2 f = fract(qd - 0.5);
	float e0 = hard ? 0.40 : 0.20;
	float e1 = hard ? 0.60 : 0.80;
	f = smoothstep(vec2(e0), vec2(e1), f);

	int t00 = tile_at(c);
	int t10 = tile_at(c + ivec2(1, 0));
	int t01 = tile_at(c + ivec2(0, 1));
	int t11 = tile_at(c + ivec2(1, 1));
	float w00 = (1.0 - f.x) * (1.0 - f.y);
	float w10 = f.x * (1.0 - f.y);
	float w01 = (1.0 - f.x) * f.y;
	float w11 = f.x * f.y;

	vec3 col = vec3(0.0);
	float water_w = 0.0;
	if (w00 > 0.002) { col += w00 * terrain(t00, q, TIME); if (t00 == 9) water_w += w00; }
	if (w10 > 0.002) { col += w10 * terrain(t10, q, TIME); if (t10 == 9) water_w += w10; }
	if (w01 > 0.002) { col += w01 * terrain(t01, q, TIME); if (t01 == 9) water_w += w01; }
	if (w11 > 0.002) { col += w11 * terrain(t11, q, TIME); if (t11 == 9) water_w += w11; }

	// Foam along the shoreline, and a darker wet edge on the land beside it.
	float shore = smoothstep(0.05, 0.5, water_w) * smoothstep(0.98, 0.45, water_w);
	float foam = shore * smoothstep(0.35, 0.6, vnoise(q * vec2(4.0, 4.0) + vec2(TIME * 0.4, TIME * 0.3)));
	col = mix(col, vec3(0.95, 0.98, 1.0), foam * 0.85);
	col *= 1.0 - 0.18 * smoothstep(0.0, 0.5, shore) * step(water_w, 0.5);
	COLOR = vec4(col, 1.0);
}
