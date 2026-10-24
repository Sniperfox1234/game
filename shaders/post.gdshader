shader_type canvas_item;
// Full-screen finishing: a soft vignette, a gentle tilt-shift blur toward the top and bottom of the
// screen (depth), and a touch of colour grading.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float vignette = 0.30;
uniform float blur = 1.1;
uniform float saturation = 1.10;
uniform float contrast = 1.05;
uniform vec3 tint = vec3(1.0, 0.99, 0.96);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - vec2(0.5);
	float edge = smoothstep(0.34, 0.52, abs(d.y));
	vec2 px = SCREEN_PIXEL_SIZE * blur * (0.25 + 1.5 * edge);
	vec3 c = texture(screen_tex, uv).rgb * 0.36;
	c += texture(screen_tex, uv + vec2(px.x, 0.0)).rgb * 0.16;
	c += texture(screen_tex, uv - vec2(px.x, 0.0)).rgb * 0.16;
	c += texture(screen_tex, uv + vec2(0.0, px.y)).rgb * 0.16;
	c += texture(screen_tex, uv - vec2(0.0, px.y)).rgb * 0.16;
	// restore some crispness in the centre of the screen
	vec3 sharp = texture(screen_tex, uv).rgb;
	c = mix(c, sharp, 0.35 + (1.0 - edge) * 0.55);
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(lum), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	float v = 1.0 - smoothstep(0.32, 0.98, length(d * vec2(1.0, 0.92))) * vignette;
	COLOR = vec4(c * v * tint, 1.0);
}
