shader_type canvas_item;

uniform sampler2D screen_texture
	: hint_screen_texture, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 1.0) = 1.0;

uniform float wobble_strength : hint_range(0.0, 0.1) = 0.018;
uniform float wobble_speed : hint_range(0.0, 10.0) = 2.5;
uniform float wobble_scale : hint_range(1.0, 30.0) = 10.0;

uniform float fisheye_strength : hint_range(-1.0, 1.0) = 0.18;
uniform float swirl_strength : hint_range(-2.0, 2.0) = 0.16;

uniform float double_vision_strength : hint_range(0.0, 0.05) = 0.008;
uniform float chromatic_aberration : hint_range(0.0, 0.03) = 0.006;
uniform float colour_shift_strength : hint_range(0.0, 1.0) = 0.18;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.25;


float get_aspect_ratio() {
	ivec2 screen_size = textureSize(screen_texture, 0);

	return float(screen_size.x) / max(float(screen_size.y), 1.0);
}


vec2 apply_fisheye(
	vec2 uv,
	float strength,
	float aspect_ratio
) {
	vec2 centered_uv = uv * 2.0 - 1.0;

	centered_uv.x *= aspect_ratio;

	float distance_from_center = length(centered_uv);
	float distortion = (
		1.0 +
		strength *
		distance_from_center *
		distance_from_center
	);

	centered_uv *= distortion;
	centered_uv.x /= aspect_ratio;

	return centered_uv * 0.5 + 0.5;
}


vec2 apply_swirl(
	vec2 uv,
	float strength,
	float aspect_ratio
) {
	vec2 centered_uv = uv - vec2(0.5);

	centered_uv.x *= aspect_ratio;

	float distance_from_center = length(centered_uv);

	float angle = strength * (
		1.0 -
		smoothstep(0.0, 0.85, distance_from_center)
	);

	float sine = sin(angle);
	float cosine = cos(angle);

	centered_uv = mat2(
		vec2(cosine, -sine),
		vec2(sine, cosine)
	) * centered_uv;

	centered_uv.x /= aspect_ratio;

	return centered_uv + vec2(0.5);
}


vec2 apply_wobble(vec2 uv) {
	float time = TIME * wobble_speed;

	float horizontal_wave = (
		sin(uv.y * wobble_scale + time) +
		sin(
			uv.y * wobble_scale * 2.31 -
			time * 1.37
		)
	);

	float vertical_wave = (
		cos(
			uv.x * wobble_scale * 0.83 -
			time * 1.12
		) +
		sin(
			(uv.x + uv.y) *
			wobble_scale *
			1.71 +
			time *
			0.74
		)
	);

	return uv + vec2(
		horizontal_wave,
		vertical_wave
	) * wobble_strength * 0.5;
}


vec3 sample_chromatic(
	vec2 uv,
	vec2 direction,
	float amount
) {
	vec2 red_uv = clamp(
		uv + direction * amount,
		vec2(0.0),
		vec2(1.0)
	);

	vec2 blue_uv = clamp(
		uv - direction * amount,
		vec2(0.0),
		vec2(1.0)
	);

	float red = texture(
		screen_texture,
		red_uv
	).r;

	float green = texture(
		screen_texture,
		clamp(uv, vec2(0.0), vec2(1.0))
	).g;

	float blue = texture(
		screen_texture,
		blue_uv
	).b;

	return vec3(red, green, blue);
}


void fragment() {
	vec2 original_uv = SCREEN_UV;
	vec2 distorted_uv = original_uv;

	float aspect_ratio = get_aspect_ratio();

	float animated_fisheye = (
		fisheye_strength +
		sin(TIME * 1.3) * 0.035
	);

	distorted_uv = apply_fisheye(
		distorted_uv,
		animated_fisheye * intensity,
		aspect_ratio
	);

	distorted_uv = apply_swirl(
		distorted_uv,
		swirl_strength * intensity,
		aspect_ratio
	);

	vec2 wobbled_uv = apply_wobble(distorted_uv);

	distorted_uv = mix(
		distorted_uv,
		wobbled_uv,
		intensity
	);

	distorted_uv = clamp(
		distorted_uv,
		vec2(0.002),
		vec2(0.998)
	);

	vec2 center_direction = distorted_uv - vec2(0.5);

	vec2 separation_direction = normalize(
		center_direction + vec2(0.0001)
	);

	vec3 main_colour = sample_chromatic(
		distorted_uv,
		separation_direction,
		chromatic_aberration * intensity
	);

	vec2 double_offset = vec2(
		sin(TIME * 2.2),
		cos(TIME * 1.7)
	) * double_vision_strength * intensity;

	vec3 double_colour = texture(
		screen_texture,
		clamp(
			distorted_uv + double_offset,
			vec2(0.0),
			vec2(1.0)
		)
	).rgb;

	main_colour = mix(
		main_colour,
		double_colour,
		0.24 * intensity
	);

	float colour_wave = sin(
		TIME * 1.8 +
		original_uv.y * 8.0
	);

	vec3 shifted_colour = vec3(
		main_colour.g,
		main_colour.b,
		main_colour.r
	);

	main_colour = mix(
		main_colour,
		shifted_colour,
		colour_shift_strength *
		intensity *
		(colour_wave * 0.5 + 0.5)
	);

	vec2 centered_uv = original_uv * 2.0 - 1.0;
	centered_uv.x *= aspect_ratio;

	float vignette = smoothstep(
		0.25,
		1.1,
		length(centered_uv)
	);

	main_colour *= (
		1.0 -
		vignette *
		vignette_strength *
		intensity
	);

	vec3 original_colour = texture(
		screen_texture,
		original_uv
	).rgb;

	COLOR = vec4(
		mix(
			original_colour,
			main_colour,
			intensity
		),
		1.0
	);
}