shader_type canvas_item;

uniform vec2 rect_size = vec2(128.0, 128.0);
uniform float radius = 64.0;
uniform float edge_softness = 6.0;
uniform vec4 fill_color : source_color = vec4(0.75, 0.45, 0.1, 0.28);
uniform vec4 line_color : source_color = vec4(0.85, 0.5, 0.1, 0.22);
uniform float line_count : hint_range(3.0, 12.0) = 7.0;
uniform float line_width = 1.4;
uniform float wave_amplitude = 5.5;
uniform float wave_frequency = 0.2;
uniform float wave_speed = 1.4;

float wrap_angle(float a) {
	return mod(a + PI, TAU) - PI;
}

void fragment() {
	vec2 pos = (UV - vec2(0.5)) * rect_size;
	float dist = length(pos);
	float angle = atan(pos.y, pos.x);

	float fill_alpha = 1.0 - smoothstep(radius - edge_softness, radius, dist);

	float sector = TAU / line_count;
	float arm_angle = round(angle / sector) * sector;
	float delta = wrap_angle(angle - arm_angle);
	float lateral = dist * delta;
	float wave = sin(dist * wave_frequency + TIME * wave_speed + arm_angle * 3.0) * wave_amplitude;
	float line_dist = abs(lateral - wave);
	float line_mask = 1.0 - smoothstep(line_width * 0.5, line_width * 1.5, line_dist);

	float fade_in = smoothstep(0.0, radius * 0.25, dist);
	float fade_out = 1.0 - smoothstep(radius * 0.55, radius * 0.9, dist);
	float line_alpha = line_mask * fade_in * fade_out;

	vec4 color = mix(fill_color, line_color, line_alpha);
	float alpha = max(fill_color.a * fill_alpha, line_color.a * line_alpha);
	COLOR = vec4(color.rgb, alpha);
}
