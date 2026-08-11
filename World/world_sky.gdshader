shader_type sky;

uniform vec3 zenith_color : source_color =
	vec3(0.075, 0.29, 0.48);

uniform vec3 upper_color : source_color =
	vec3(0.24, 0.56, 0.68);

uniform vec3 horizon_color : source_color =
	vec3(0.72, 0.88, 0.72);

uniform vec3 lower_color : source_color =
	vec3(0.19, 0.37, 0.31);

uniform vec3 cloud_shadow_color : source_color =
	vec3(0.3, 0.52, 0.56);

uniform vec3 cloud_color : source_color =
	vec3(0.86, 0.96, 0.9);

uniform vec3 cloud_highlight_color : source_color =
	vec3(1.0, 0.94, 0.7);

uniform vec3 magic_color : source_color =
	vec3(0.25, 0.9, 0.82);

uniform vec3 sparkle_color : source_color =
	vec3(0.85, 1.0, 0.78);

uniform vec3 sun_color : source_color =
	vec3(1.0, 0.82, 0.44);

uniform float animation_speed :
	hint_range(0.0, 2.0) = 0.025;

uniform float cloud_scale :
	hint_range(1.0, 20.0) = 5.0;

uniform float cloud_coverage :
	hint_range(0.0, 1.0) = 0.48;

uniform float cloud_softness :
	hint_range(0.01, 0.5) = 0.16;

uniform float cloud_strength :
	hint_range(0.0, 2.0) = 0.9;

uniform float magic_strength :
	hint_range(0.0, 2.0) = 0.22;

uniform float sparkle_strength :
	hint_range(0.0, 5.0) = 0.45;

uniform float sun_size :
	hint_range(0.001, 0.2) = 0.022;

uniform float sun_glow_size :
	hint_range(0.01, 0.5) = 0.16;

uniform float sun_strength :
	hint_range(0.0, 10.0) = 2.0;

uniform float brightness :
	hint_range(0.0, 3.0) = 1.0;


float hash_3d(vec3 position) {
	position = fract(
		position * 0.1031
	);

	position += dot(
		position,
		position.yzx + 33.33
	);

	return fract(
		(position.x + position.y)
		* position.z
	);
}


float noise_3d(vec3 position) {
	vec3 cell = floor(position);
	vec3 fraction = fract(position);

	fraction =
		fraction
		* fraction
		* (3.0 - 2.0 * fraction);

	float n000 = hash_3d(
		cell + vec3(0.0, 0.0, 0.0)
	);

	float n100 = hash_3d(
		cell + vec3(1.0, 0.0, 0.0)
	);

	float n010 = hash_3d(
		cell + vec3(0.0, 1.0, 0.0)
	);

	float n110 = hash_3d(
		cell + vec3(1.0, 1.0, 0.0)
	);

	float n001 = hash_3d(
		cell + vec3(0.0, 0.0, 1.0)
	);

	float n101 = hash_3d(
		cell + vec3(1.0, 0.0, 1.0)
	);

	float n011 = hash_3d(
		cell + vec3(0.0, 1.0, 1.0)
	);

	float n111 = hash_3d(
		cell + vec3(1.0, 1.0, 1.0)
	);

	float bottom = mix(
		mix(
			n000,
			n100,
			fraction.x
		),
		mix(
			n010,
			n110,
			fraction.x
		),
		fraction.y
	);

	float top = mix(
		mix(
			n001,
			n101,
			fraction.x
		),
		mix(
			n011,
			n111,
			fraction.x
		),
		fraction.y
	);

	return mix(
		bottom,
		top,
		fraction.z
	);
}


float fbm(vec3 position) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int index = 0; index < 5; index++) {
		value +=
			noise_3d(position)
			* amplitude;

		position =
			position * 2.03
			+ vec3(7.3, 11.7, 5.2);

		amplitude *= 0.5;
	}

	return value;
}


vec2 rotate_2d(
	vec2 position,
	float angle
) {
	float angle_cosine = cos(angle);
	float angle_sine = sin(angle);

	return vec2(
		position.x * angle_cosine
			- position.y * angle_sine,
		position.x * angle_sine
			+ position.y * angle_cosine
	);
}


void sky() {
	vec3 direction = normalize(EYEDIR);

	float time =
		TIME * animation_speed;

	float height = direction.y;

	float upper_height = clamp(
		height,
		0.0,
		1.0
	);

	float lower_height = clamp(
		-height,
		0.0,
		1.0
	);

	float horizon = pow(
		1.0 - abs(height),
		4.0
	);


	vec3 color = mix(
		upper_color,
		zenith_color,
		pow(
			upper_height,
			0.7
		)
	);

	color = mix(
		color,
		lower_color,
		pow(
			lower_height,
			0.65
		)
	);

	color = mix(
		color,
		horizon_color,
		horizon * 0.78
	);


	vec3 moving_direction = direction;

	vec2 rotated_direction = rotate_2d(
		moving_direction.xz,
		time
	);

	moving_direction.x = rotated_direction.x;
	moving_direction.z = rotated_direction.y;


	float cloud_height_mask = smoothstep(
		-0.02,
		0.18,
		direction.y
	);

	cloud_height_mask *=
		1.0 - smoothstep(
			0.62,
			0.95,
			direction.y
		);

	float large_clouds = fbm(
		moving_direction * cloud_scale
		+ vec3(
			time * 2.0,
			0.0,
			-time * 1.15
		)
	);

	float cloud_details = fbm(
		moving_direction
		* cloud_scale
		* 2.4
		- vec3(
			time * 3.2,
			time * 0.2,
			time * 1.6
		)
	);

	float cloud_noise =
		large_clouds * 0.72
		+ cloud_details * 0.28;

	float cloud_threshold = mix(
		0.72,
		0.38,
		cloud_coverage
	);

	float cloud_mask = smoothstep(
		cloud_threshold,
		cloud_threshold + cloud_softness,
		cloud_noise
	);

	cloud_mask *= cloud_height_mask;


	float cloud_light =
		cloud_details * 0.55
		+ upper_height * 0.45;

	vec3 current_cloud_color = mix(
		cloud_shadow_color,
		cloud_color,
		smoothstep(
			0.25,
			0.82,
			cloud_light
		)
	);

	float sun_side = clamp(
		dot(
			direction,
			normalize(
				vec3(
					-0.42,
					0.5,
					-0.76
				)
			)
		) * 0.5 + 0.5,
		0.0,
		1.0
	);

	current_cloud_color = mix(
		current_cloud_color,
		cloud_highlight_color,
		pow(
			sun_side,
			5.0
		) * cloud_mask
	);

	color = mix(
		color,
		current_cloud_color,
		cloud_mask
		* cloud_strength
	);


	float sky_angle = atan(
		direction.z,
		direction.x
	);

	float magic_noise = fbm(
		moving_direction * 8.0
		+ vec3(
			time * 3.5,
			-time * 0.5,
			time * 2.0
		)
	);

	float magic_wave = sin(
		sky_angle * 4.0
		+ direction.y * 15.0
		- time * 6.0
		+ magic_noise * 4.0
	);

	magic_wave = smoothstep(
		0.62,
		1.0,
		magic_wave
	);

	float magic_region = smoothstep(
		0.02,
		0.28,
		direction.y
	);

	magic_region *=
		1.0 - smoothstep(
			0.38,
			0.72,
			direction.y
		);

	float magic_wisps =
		magic_wave
		* magic_region
		* magic_noise;

	magic_wisps *=
		1.0 - cloud_mask * 0.75;

	color +=
		magic_color
		* magic_wisps
		* magic_strength;


	vec3 sparkle_cell = floor(
		direction * 280.0
	);

	float sparkle_random = hash_3d(
		sparkle_cell
	);

	float sparkles = smoothstep(
		0.989,
		1.0,
		sparkle_random
	);

	float sparkle_shape = noise_3d(
		direction * 650.0
	);

	sparkles *= smoothstep(
		0.58,
		0.82,
		sparkle_shape
	);

	float twinkle =
		0.7
		+ 0.3
		* sin(
			TIME * 1.4
			+ sparkle_random * 40.0
		);

	sparkles *= twinkle;

	sparkles *= smoothstep(
		0.0,
		0.35,
		direction.y
	);

	sparkles *=
		1.0 - cloud_mask;

	color +=
		sparkle_color
		* sparkles
		* sparkle_strength;


	vec3 sun_direction = normalize(
		vec3(
			-0.4067,
			0.7071,
			0.5792
		)
	);

	float sun_distance =
		1.0
		- dot(
			direction,
			sun_direction
		);

	float sun =
		1.0 - smoothstep(
			sun_size * 0.72,
			sun_size,
			sun_distance
		);

	float sun_inner =
		1.0 - smoothstep(
			sun_size * 0.2,
			sun_size * 0.72,
			sun_distance
		);

	float sun_glow =
		1.0 - smoothstep(
			sun_size,
			sun_glow_size,
			sun_distance
		);

	sun_glow = pow(
		sun_glow,
		2.5
	);

	color +=
		sun_color
		* sun_glow
		* sun_strength;

	vec3 sun_surface = mix(
		sun_color,
		vec3(1.0, 0.98, 0.82),
		sun_inner
	);

	color = mix(
		color,
		sun_surface
		* sun_strength,
		sun
	);


	float horizon_noise = fbm(
		direction * 18.0
		+ vec3(
			time * 2.0,
			0.0,
			-time
		)
	);

	float horizon_glow = smoothstep(
		0.56,
		0.88,
		horizon_noise
	);

	horizon_glow *= horizon;

	color +=
		magic_color
		* horizon_glow
		* 0.08;


	COLOR = color * brightness;
}