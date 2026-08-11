class_name Enemy
extends CharacterBody3D


signal state_changed(new_state: State)

signal idle_started
signal wander_started(target_position: Vector3)
signal chase_started(target: Node3D)
signal attack_started(target: Node3D)


enum State {
	IDLE,
	WANDER,
	CHASE,
	ATTACK
}


@export_category("Target")
@export var target: Node3D
@export var detection_distance: float = 10.0
@export var attack_distance: float = 2.0
@export var lose_target_distance: float = 15.0

@export_category("Movement")
@export var move_speed: float = 4.0
@export var acceleration: float = 12.0
@export var rotation_speed: float = 8.0
@export var gravity: float = 20.0

@export_category("Wandering")
@export var wander_radius: float = 8.0
@export var minimum_idle_time: float = 1.0
@export var maximum_idle_time: float = 3.0
@export var wander_target_tolerance: float = 0.75

@export_category("Attacking")
@export var attack_cooldown: float = 1.5


@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer


var current_state: State = State.IDLE
var spawn_position: Vector3
var idle_time_remaining: float = 0.0
var can_attack: bool = true


func _ready() -> void:
	spawn_position = global_position

	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.wait_time = attack_cooldown
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_finished)

	# Navigation data may not be ready during the first frame.
	await get_tree().physics_frame

	change_state(State.IDLE)


func _physics_process(delta: float) -> void:
	apply_gravity(delta)

	match current_state:
		State.IDLE:
			process_idle(delta)

		State.WANDER:
			process_wander(delta)

		State.CHASE:
			process_chase(delta)

		State.ATTACK:
			process_attack()

	move_and_slide()


func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(current_state)

	match current_state:
		State.IDLE:
			enter_idle()

		State.WANDER:
			enter_wander()

		State.CHASE:
			enter_chase()

		State.ATTACK:
			enter_attack()


# Idle

func enter_idle() -> void:
	stop_moving()

	idle_time_remaining = randf_range(
		minimum_idle_time,
		maximum_idle_time
	)

	idle_started.emit()


func process_idle(delta: float) -> void:
	if can_detect_target():
		change_state(State.CHASE)
		return

	idle_time_remaining -= delta

	if idle_time_remaining <= 0.0:
		change_state(State.WANDER)


# Wander

func enter_wander() -> void:
	var wander_position: Vector3 = get_random_wander_position()
	nav_agent.target_position = wander_position

	wander_started.emit(wander_position)


func process_wander(delta: float) -> void:
	if can_detect_target():
		change_state(State.CHASE)
		return

	if nav_agent.is_navigation_finished():
		change_state(State.IDLE)
		return

	var distance_to_target: float = global_position.distance_to(
		nav_agent.target_position
	)

	if distance_to_target <= wander_target_tolerance:
		change_state(State.IDLE)
		return

	follow_navigation_path(delta, move_speed)


func get_random_wander_position() -> Vector3:
	var random_offset: Vector3 = Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)

	var desired_position: Vector3 = spawn_position + random_offset
	var navigation_map: RID = nav_agent.get_navigation_map()

	if not navigation_map.is_valid():
		return desired_position

	return NavigationServer3D.map_get_closest_point(
		navigation_map,
		desired_position
	)


# Chase

func enter_chase() -> void:
	if not is_instance_valid(target):
		change_state(State.IDLE)
		return

	chase_started.emit(target)


func process_chase(delta: float) -> void:
	if not is_instance_valid(target):
		change_state(State.IDLE)
		return

	var distance: float = global_position.distance_to(target.global_position)

	if distance > lose_target_distance:
		change_state(State.IDLE)
		return

	if distance <= attack_distance:
		change_state(State.ATTACK)
		return

	nav_agent.target_position = target.global_position
	follow_navigation_path(delta, move_speed)


# Attack

func enter_attack() -> void:
	stop_moving()


func process_attack() -> void:
	if not is_instance_valid(target):
		change_state(State.IDLE)
		return

	var distance: float = global_position.distance_to(target.global_position)

	if distance > attack_distance:
		change_state(State.CHASE)
		return

	rotate_towards_position(target.global_position, get_physics_process_delta_time())

	if can_attack:
		perform_attack()


func perform_attack() -> void:
	can_attack = false

	attack_started.emit(target)

	attack_cooldown_timer.start(attack_cooldown)


func _on_attack_cooldown_finished() -> void:
	can_attack = true


# Movement

func follow_navigation_path(delta: float, speed: float) -> void:
	if nav_agent.is_navigation_finished():
		stop_moving()
		return

	var next_position: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(next_position)
	direction.y = 0.0

	if direction.is_zero_approx():
		stop_moving()
		return

	direction = direction.normalized()

	velocity.x = move_toward(
		velocity.x,
		direction.x * speed,
		acceleration * delta
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * speed,
		acceleration * delta
	)

	rotate_towards_direction(direction, delta)


func stop_moving() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func rotate_towards_direction(direction: Vector3, delta: float) -> void:
	var target_angle: float = atan2(direction.x, direction.z)

	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		rotation_speed * delta
	)


func rotate_towards_position(target_position: Vector3, delta: float) -> void:
	var direction: Vector3 = global_position.direction_to(target_position)
	direction.y = 0.0

	if not direction.is_zero_approx():
		rotate_towards_direction(direction.normalized(), delta)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


# Target detection

func can_detect_target() -> bool:
	if not is_instance_valid(target):
		return false

	return global_position.distance_to(
		target.global_position
	) <= detection_distance


func set_target(new_target: Node3D) -> void:
	target = new_target


func clear_target() -> void:
	target = null

	if current_state == State.CHASE or current_state == State.ATTACK:
		change_state(State.IDLE)