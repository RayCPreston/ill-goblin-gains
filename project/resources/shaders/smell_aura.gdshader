shader_type canvas_item;

uniform vec2 rect_size = vec2(128.0, 128.0);
uniform float radius = 64.0;
uniform float edge_softness = 5.0;
uniform float edge_noise_amplitude = 6.0;
uniform float edge_noise_speed = 0.5;
uniform vec4 color_a : source_color = vec4(0.45, 0.42, 0.12, 0.32);
uniform vec4 color_b : source_color = vec4(0.32, 0.2, 0.08, 0.32);
uniform float color_noise_scale = 0.06;
uniform float color_shift_speed = 0.15;

float hash1(float n) {
	return fract(sin(n) * 43758.5453123);
}

float value_noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	float a = hash1(i);
	float b = hash1(i + 1.0);
	return mix(a, b, smoothstep(0.0, 1.0, f));
}

float edge_noise(float angle, float t) {
	float n = value_noise1(angle * 3.0 + t) * 0.6
			+ value_noise1(angle * 7.0 - t * 1.6) * 0.4;
	return n * 2.0 - 1.0;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash2(i);
	float b = hash2(i + vec2(1.0, 0.0));
	float c = hash2(i + vec2(0.0, 1.0));
	float d = hash2(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 pos = (UV - vec2(0.5)) * rect_size;
	float dist = length(pos);
	float angle = atan(pos.y, pos.x);

	float wobble = edge_noise(angle, TIME * edge_noise_speed) * edge_noise_amplitude;
	float edge_radius = radius + wobble;
	float fill_alpha = 1.0 - smoothstep(edge_radius - edge_softness, edge_radius, dist);

	vec2 drift = vec2(TIME * color_shift_speed, TIME * color_shift_speed * 0.7);
	float color_n = value_noise2(pos * color_noise_scale + drift);
	vec4 color = mix(color_a, color_b, color_n);

	COLOR = vec4(color.rgb, color.a * fill_alpha);
}
