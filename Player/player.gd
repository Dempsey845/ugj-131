class_name Player
extends CharacterBody3D

signal jumped
signal landed
signal slide_started
signal slide_ended
signal slide_hit(target: Node3D)
signal knocked_down
signal recovered


@export_category("References")
@export var camera_pivot: Node3D
@export var visuals: Node3D
@export var standing_collision: CollisionShape3D
@export var slide_hitbox: Area3D
@export var name_label: Label3D


@export_category("Movement")
@export var move_speed: float = 7.0
@export var ground_acceleration: float = 35.0
@export var ground_deceleration: float = 30.0
@export var air_acceleration: float = 10.0
@export var rotation_speed: float = 12.0


@export_category("Jumping")
@export var gravity: float = 22.0
@export var jump_velocity: float = 9.0
@export var fall_gravity_multiplier: float = 1.4
@export var jump_cut_gravity_multiplier: float = 2.5
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15


@export_category("Sliding")
@export var slide_start_speed: float = 13.0
@export var minimum_slide_speed: float = 5.0
@export var slide_deceleration: float = 11.0
@export var slide_duration: float = 0.75
@export var slide_steering: float = 2.5
@export var slide_cooldown: float = 0.4
@export var slide_visual_height: float = 0.55

@export_category("Tackle Reaction")
@export var tackle_knockback_speed: float = 8.0
@export var tackle_upward_speed: float = 2.5
@export var tackle_friction: float = 14.0
@export var knocked_down_duration: float = 0.65
@export var recovery_duration: float = 0.3
@export var recovery_control: float = 0.35

var is_knocked_down: bool = false
var is_recovering: bool = false

var knocked_down_remaining: float = 0.0
var recovery_remaining: float = 0.0

var knockback_direction: Vector3
var default_visual_rotation: Vector3

@export_category("Camera")
@export var mouse_sensitivity: float = 0.003
@export var controller_look_sensitivity: float = 2.5
@export var minimum_pitch: float = deg_to_rad(-55.0)
@export var maximum_pitch: float = deg_to_rad(40.0)

@export_category("Slippery Movement")
@export var slippery_acceleration: float = 5.0
@export var slippery_deceleration: float = 1.5

@export_category("Goofy Movement")
@export var goofy_wobble_strength: float = 0.8
@export var goofy_wobble_speed: float = 4.0
@export var goofy_secondary_wobble: float = 0.4

var slippery_area_count: int = 0

var is_on_slippery_surface: bool:
	get:
		return slippery_area_count > 0

var can_move: bool = true
var move_speed_multiplier: float = 1.0

var is_sliding: bool = false
var slide_direction: Vector3
var current_slide_speed: float
var slide_time_remaining: float
var slide_cooldown_remaining: float

var coyote_time_remaining: float
var jump_buffer_remaining: float
var was_on_floor: bool

var default_visual_position: Vector3
var hit_targets: Array[Node3D] = []

var goofy_movement_enabled: bool = false
var goofy_wobble_phase: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	default_visual_position = visuals.position
	default_visual_rotation = visuals.rotation

	slide_hitbox.monitoring = false
	slide_hitbox.body_entered.connect(_on_slide_hitbox_body_entered)

	name_label.text = SceneManager.player_name


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
			camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
			camera_pivot.rotation.x = clamp(
				camera_pivot.rotation.x,
				minimum_pitch,
				maximum_pitch
			)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_controller_camera(delta)
	_update_ground_tracking(delta)

	if is_knocked_down:
		_update_knocked_down(delta)
		_apply_gravity(delta)
		move_and_slide()
		_check_landing()
		return

	var input_direction: Vector3 = _get_movement_direction()

	if is_recovering:
		_update_recovery(delta, input_direction)
		_apply_gravity(delta)
		move_and_slide()
		_check_landing()
		_rotate_visuals(delta)
		return

	_buffer_jump()

	if Input.is_action_just_pressed("slide"):
		_try_start_slide(input_direction)

	if is_sliding:
		_update_slide(delta, input_direction)
	else:
		_update_movement(delta, input_direction)
		_try_jump()

	_apply_gravity(delta)
	move_and_slide()

	_check_landing()
	_rotate_visuals(delta)


func _update_timers(delta: float) -> void:
	slide_cooldown_remaining = maxf(
		slide_cooldown_remaining - delta,
		0.0
	)

	jump_buffer_remaining = maxf(
		jump_buffer_remaining - delta,
		0.0
	)


func _update_controller_camera(delta: float) -> void:
	var look_input: Vector2 = Input.get_vector(
		"look_left",
		"look_right",
		"look_up",
		"look_down"
	)

	camera_pivot.rotation.y -= (
		look_input.x *
		controller_look_sensitivity *
		delta
	)

	camera_pivot.rotation.x -= (
		look_input.y *
		controller_look_sensitivity *
		delta
	)

	camera_pivot.rotation.x = clamp(
		camera_pivot.rotation.x,
		minimum_pitch,
		maximum_pitch
	)


func _update_ground_tracking(delta: float) -> void:
	if is_on_floor():
		coyote_time_remaining = coyote_time
	else:
		coyote_time_remaining = maxf(
			coyote_time_remaining - delta,
			0.0
		)


func _buffer_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_remaining = jump_buffer_time


func _get_movement_direction() -> Vector3:
	if not can_move:
		return Vector3.ZERO

	var input: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	if input.length_squared() == 0.0:
		return Vector3.ZERO

	var camera_forward: Vector3 = -camera_pivot.global_transform.basis.z
	var camera_right: Vector3 = camera_pivot.global_transform.basis.x

	camera_forward.y = 0.0
	camera_right.y = 0.0

	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

	return (
		camera_right * input.x +
		camera_forward * -input.y
	).normalized()


func _update_movement(
	delta: float,
	input_direction: Vector3
) -> void:
	var movement_direction: Vector3 = (
		_apply_goofy_movement(input_direction)
	)

	var target_velocity: Vector3 = (
		movement_direction
		* move_speed
		* move_speed_multiplier
	)

	var acceleration: float

	if not is_on_floor():
		acceleration = air_acceleration

	elif is_on_slippery_surface:
		if input_direction == Vector3.ZERO:
			acceleration = slippery_deceleration
		else:
			acceleration = slippery_acceleration

	elif input_direction == Vector3.ZERO:
		acceleration = ground_deceleration

	else:
		acceleration = ground_acceleration

	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		target_velocity.z,
		acceleration * delta
	)

func _apply_goofy_movement(
	direction: Vector3
) -> Vector3:
	if not goofy_movement_enabled:
		return direction

	if direction.length_squared() <= 0.001:
		return direction

	var forward: Vector3 = direction.normalized()

	var sideways: Vector3 = Vector3(
		-forward.z,
		0.0,
		forward.x
	)

	var time: float = (
		Time.get_ticks_msec() * 0.001
		+ goofy_wobble_phase
	)

	var wobble: float = (
		sin(time * goofy_wobble_speed)
		* goofy_wobble_strength
	)

	wobble += (
		sin(
			time * goofy_wobble_speed * 2.17
			+ 1.4
		)
		* goofy_secondary_wobble
	)

	return (
		forward + sideways * wobble
	).normalized()

func _try_jump() -> void:
	if jump_buffer_remaining <= 0.0:
		return

	if coyote_time_remaining <= 0.0:
		return

	jump_buffer_remaining = 0.0
	coyote_time_remaining = 0.0

	velocity.y = jump_velocity
	jumped.emit()


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y <= 0.0:
		velocity.y = -0.5
		return

	var gravity_multiplier: float = 1.0

	if velocity.y < 0.0:
		gravity_multiplier = fall_gravity_multiplier
	elif velocity.y > 0.0 and not Input.is_action_pressed("jump"):
		gravity_multiplier = jump_cut_gravity_multiplier

	velocity.y -= gravity * gravity_multiplier * delta


func _try_start_slide(input_direction: Vector3) -> void:
	if is_sliding:
		return

	if slide_cooldown_remaining > 0.0:
		return

	if not is_on_floor():
		return

	if not can_move:
		return

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	if input_direction != Vector3.ZERO:
		slide_direction = input_direction
	elif horizontal_velocity.length() > 0.1:
		slide_direction = horizontal_velocity.normalized()
	else:
		slide_direction = -visuals.global_transform.basis.z
		slide_direction.y = 0.0
		slide_direction = slide_direction.normalized()

	is_sliding = true
	slide_time_remaining = slide_duration
	current_slide_speed = maxf(
		horizontal_velocity.length(),
		slide_start_speed
	)

	hit_targets.clear()
	slide_hitbox.monitoring = true

	_lower_visuals()
	slide_started.emit()


func _update_slide(
	delta: float,
	input_direction: Vector3
) -> void:
	slide_time_remaining -= delta

	if input_direction != Vector3.ZERO:
		slide_direction = slide_direction.move_toward(
			input_direction,
			slide_steering * delta
		).normalized()

	current_slide_speed = move_toward(
		current_slide_speed,
		0.0,
		slide_deceleration * delta
	)

	velocity.x = slide_direction.x * current_slide_speed * move_speed_multiplier
	velocity.z = slide_direction.z * current_slide_speed * move_speed_multiplier

	if (
		slide_time_remaining <= 0.0
		or current_slide_speed <= minimum_slide_speed
		or not is_on_floor()
	):
		_end_slide()


func _end_slide() -> void:
	if not is_sliding:
		return

	is_sliding = false
	slide_cooldown_remaining = slide_cooldown
	slide_hitbox.set_deferred("monitoring", false)

	_restore_visuals()
	slide_ended.emit()


func _lower_visuals() -> void:
	var target_position: Vector3 = default_visual_position
	target_position.y -= slide_visual_height

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		visuals,
		"position",
		target_position,
		0.12
	)


func _restore_visuals() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		visuals,
		"position",
		default_visual_position,
		0.15
	)


func _rotate_visuals(delta: float) -> void:
	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	if horizontal_velocity.length_squared() < 0.05:
		return

	var target_direction: Vector3 = horizontal_velocity.normalized()
	var target_angle: float = atan2(
		-target_direction.x,
		-target_direction.z
	)

	visuals.rotation.y = lerp_angle(
		visuals.rotation.y,
		target_angle,
		rotation_speed * delta
	)


func _check_landing() -> void:
	if is_on_floor() and not was_on_floor:
		landed.emit()

	was_on_floor = is_on_floor()


func _on_slide_hitbox_body_entered(body: Node3D) -> void:
	if not is_sliding:
		return

	if body == self:
		return

	if body in hit_targets:
		return

	if not body.has_method("receive_tackle"):
		return

	hit_targets.append(body)
	body.receive_tackle(slide_direction, self)
	slide_hit.emit(body)

func receive_tackle(
	direction: Vector3,
	_attacker: Node3D
) -> void:
	if is_knocked_down:
		return

	if is_sliding:
		_end_slide()

	knockback_direction = direction
	knockback_direction.y = 0.0

	if knockback_direction.length_squared() <= 0.001:
		knockback_direction = -global_transform.basis.z
	else:
		knockback_direction = knockback_direction.normalized()

	is_knocked_down = true
	is_recovering = false
	knocked_down_remaining = knocked_down_duration

	velocity.x = knockback_direction.x * tackle_knockback_speed
	velocity.z = knockback_direction.z * tackle_knockback_speed
	velocity.y = tackle_upward_speed

	knocked_down.emit()


func _update_knocked_down(delta: float) -> void:
	knocked_down_remaining -= delta

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	horizontal_velocity = horizontal_velocity.move_toward(
		Vector3.ZERO,
		tackle_friction * delta
	)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if knocked_down_remaining > 0.0:
		return

	if not is_on_floor():
		return

	is_knocked_down = false
	is_recovering = true
	recovery_remaining = recovery_duration

func _update_recovery(
	delta: float,
	input_direction: Vector3
) -> void:
	recovery_remaining -= delta

	var target_velocity: Vector3 = (
		input_direction *
		move_speed *
		recovery_control
	)

	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		ground_acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		target_velocity.z,
		ground_acceleration * delta
	)

	if recovery_remaining <= 0.0:
		is_recovering = false
		recovered.emit()

func enter_slippery_area() -> void:
	slippery_area_count += 1

func exit_slippery_area() -> void:
	slippery_area_count = maxi(slippery_area_count - 1, 0)

func get_character_name():
	return SceneManager.player_name

func set_goofy_movement_enabled(enabled: bool) -> void:
	goofy_movement_enabled = enabled

	if enabled:
		goofy_wobble_phase = randf_range(0.0, TAU)


func enable_goofy_movement() -> void:
	set_goofy_movement_enabled(true)


func disable_goofy_movement() -> void:
	set_goofy_movement_enabled(false)