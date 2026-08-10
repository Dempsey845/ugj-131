shader_type spatial;

render_mode blend_mix,
	depth_prepass_alpha,
	cull_back,
	diffuse_burley,
	specular_schlick_ggx;

uniform vec4 ice_color : source_color = vec4(0.25, 0.75, 1.0, 1.0);
uniform vec4 deep_color : source_color = vec4(0.02, 0.18, 0.38, 1.0);
uniform vec4 frost_color : source_color = vec4(0.82, 0.96, 1.0, 1.0);

uniform float transparency : hint_range(0.0, 1.0) = 0.72;
uniform float roughness : hint_range(0.0, 1.0) = 0.18;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.9;

uniform float fresnel_strength : hint_range(0.0, 5.0) = 1.8;
uniform float fresnel_power : hint_range(0.1, 10.0) = 3.0;

uniform float pattern_scale : hint_range(0.1, 50.0) = 4.0;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.18;
uniform float animation_speed : hint_range(0.0, 2.0) = 0.08;

uniform float frost_amount : hint_range(0.0, 1.0) = 0.7;
uniform float frost_scale : hint_range(1.0, 100.0) = 40.0;

varying vec3 mesh_position;
varying vec3 mesh_normal;

float hash31(vec3 position) {
	position = fract(position * 0.1031);
	position += dot(position, position.yzx + 33.33);

	return fract((position.x + position.y) * position.z);
}

float value_noise(vec3 position) {
	vec3 cell = floor(position);
	vec3 noise_position = fract(position);

	noise_position = noise_position
		* noise_position
		* (3.0 - 2.0 * noise_position);

	float n000 = hash31(cell + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(cell + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(cell + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(cell + vec3(1.0, 1.0, 0.0));

	float n001 = hash31(cell + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(cell + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(cell + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(cell + vec3(1.0, 1.0, 1.0));

	float bottom = mix(
		mix(n000, n100, noise_position.x),
		mix(n010, n110, noise_position.x),
		noise_position.y
	);

	float top = mix(
		mix(n001, n101, noise_position.x),
		mix(n011, n111, noise_position.x),
		noise_position.y
	);

	return mix(bottom, top, noise_position.z);
}

float fbm(vec3 position) {
	float result = 0.0;
	float amplitude = 0.5;

	for (int i = 0; i < 4; i++) {
		result += value_noise(position) * amplitude;
		position = position * 2.03 + vec3(13.1, 7.7, 5.3);
		amplitude *= 0.5;
	}

	return result;
}

void vertex() {
	mesh_position = VERTEX;
	mesh_normal = NORMAL;
}

void fragment() {
	float time_offset = TIME * animation_speed;

	vec3 animated_position = mesh_position * pattern_scale;

	animated_position += vec3(
		time_offset,
		time_offset * 0.45,
		-time_offset * 0.7
	);

	float distortion = fbm(animated_position);

	vec3 distorted_position = mesh_position;

	distorted_position += mesh_normal
		* (distortion - 0.5)
		* distortion_strength;

	float internal_noise = fbm(
		distorted_position * pattern_scale
		+ vec3(0.0, time_offset, 0.0)
	);

	float fresnel = pow(
		1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0),
		fresnel_power
	);

	fresnel *= fresnel_strength;

	vec3 base_color = mix(
		deep_color.rgb,
		ice_color.rgb,
		internal_noise
	);

	base_color = mix(
		base_color,
		frost_color.rgb,
		clamp(fresnel, 0.0, 1.0)
	);

	float frost_noise = fbm(
		mesh_position * frost_scale
		+ vec3(4.2, 8.1, 1.7)
	);

	float frost = smoothstep(
		1.0 - frost_amount,
		1.0,
		frost_noise
	);

	frost *= 0.55 + fresnel * 0.45;

	base_color = mix(
		base_color,
		frost_color.rgb,
		clamp(frost, 0.0, 1.0)
	);

	ALBEDO = base_color;

	ROUGHNESS = mix(
		roughness,
		0.65,
		clamp(frost, 0.0, 1.0)
	);

	METALLIC = metallic;
	SPECULAR = specular;
	EMISSION = vec3(0.0);

	ALPHA = clamp(
		transparency
		+ fresnel * 0.2
		+ frost * 0.18,
		0.0,
		1.0
	);
}