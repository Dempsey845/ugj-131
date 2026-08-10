shader_type spatial;

render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

varying vec4 particle_color;

float hash21(vec2 position) {
	position = fract(position * vec2(123.34, 456.21));
	position += dot(position, position + 45.32);
	return fract(position.x * position.y);
}

float noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);

	local_position = local_position
		* local_position
		* (3.0 - 2.0 * local_position);

	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));

	return mix(
		mix(a, b, local_position.x),
		mix(c, d, local_position.x),
		local_position.y
	);
}

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);

	particle_color = COLOR;
}

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;

	centered_uv.x *= 0.8;

	float distance_from_center = length(centered_uv);

	float cloud_noise = noise(
		UV * 4.0
		+ vec2(TIME * 0.12, -TIME * 0.08)
	);

	float soft_shape = 1.0 - smoothstep(
		0.25 + cloud_noise * 0.12,
		1.0,
		distance_from_center
	);

	float wisps = smoothstep(
		0.15,
		0.85,
		noise(UV * vec2(3.0, 6.0) + vec2(0.0, -TIME * 0.18))
	);

	float opacity = soft_shape
		* mix(0.65, 1.0, wisps)
		* particle_color.a;

	ALBEDO = particle_color.rgb;
	EMISSION = particle_color.rgb * 0.35;
	ALPHA = opacity;
}