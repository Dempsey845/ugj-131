class_name NPC
extends CharacterBody3D

signal knocked_down
signal recovered
signal item_dropped(item: Node3D)

enum State {
	SEARCHING,
	CHASING,
	CARRYING,
	KNOCKED_DOWN
}


@export_category("References")
@export var visuals: Node3D
@export var navigation_agent: NavigationAgent3D
@export var item_holder: Marker3D
@export var search_points: Array[Node3D]
@export var player: Player


@export_category("Movement")
@export var move_speed: float = 4.5
@export var carrying_speed: float = 5.5
@export var acceleration: float = 15.0
@export var rotation_speed: float = 10.0
@export var gravity: float = 20.0


@export_category("Searching")
@export var search_wait_time: float = 1.0


@export_category("Tackle")
@export var knockback_speed: float = 7.0
@export var knockback_upward_speed: float = 3.0
@export var knocked_down_time: float = 0.8


var state: State = State.SEARCHING
var chase_target: Node3D
var carried_item: Item

var current_search_point: Node3D
var is_waiting: bool = false
var knocked_down_remaining: float = 0.0


func _ready() -> void:
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 1.0

	call_deferred("_choose_search_point")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	match state:
		State.SEARCHING:
			_update_searching(delta)

		State.CHASING:
			_update_chasing(delta)

		State.CARRYING:
			_update_carrying(delta)

		State.KNOCKED_DOWN:
			_update_knocked_down(delta)

	move_and_slide()


# Searching

func _update_searching(delta: float) -> void:
	if current_search_point == null:
		_choose_search_point()
		return

	if navigation_agent.is_navigation_finished():
		_wait_at_search_point()
		_slow_down(delta)
		return

	_follow_navigation(move_speed, delta)


func _choose_search_point() -> void:
	if search_points.is_empty():
		return

	var available_points: Array = search_points.filter(
		func(point: Node3D) -> bool:
			return is_instance_valid(point)
	)

	if available_points.is_empty():
		return

	current_search_point = available_points.pick_random()
	navigation_agent.target_position = current_search_point.global_position


func _wait_at_search_point() -> void:
	if is_waiting:
		return

	is_waiting = true

	await get_tree().create_timer(search_wait_time).timeout

	if state != State.SEARCHING:
		is_waiting = false
		return

	is_waiting = false
	_choose_search_point()


# Chasing

func chase(target: Node3D) -> void:
	if state == State.KNOCKED_DOWN:
		return

	chase_target = target
	state = State.CHASING


func _update_chasing(delta: float) -> void:
	if not is_instance_valid(chase_target):
		stop_chasing()
		return

	navigation_agent.target_position = chase_target.global_position
	_follow_navigation(move_speed, delta)


func stop_chasing() -> void:
	chase_target = null
	state = State.SEARCHING
	_choose_search_point()


# Carrying and fleeing

func collect_item(item: Item) -> void:
	if not is_instance_valid(item):
		return

	if carried_item != null:
		return


	if item.collect(self, item_holder):
		carried_item = item
		state = State.CARRYING
		_choose_flee_point()


func _update_carrying(delta: float) -> void:
	if carried_item == null:
		state = State.SEARCHING
		_choose_search_point()
		return

	if navigation_agent.is_navigation_finished():
		_choose_flee_point()

	_follow_navigation(carrying_speed, delta)


func _choose_flee_point() -> void:
	if search_points.is_empty():
		return

	var valid_points: Array[Node3D] = []

	for point in search_points:
		if is_instance_valid(point):
			valid_points.append(point)

	if valid_points.is_empty():
		return

	# Prefer a distant point so the NPC attempts to escape.
	valid_points.sort_custom(
		func(a: Node3D, b: Node3D) -> bool:
			var distance_a: float = global_position.distance_squared_to(
				a.global_position
			)
			var distance_b: float = global_position.distance_squared_to(
				b.global_position
			)

			return distance_a > distance_b
	)

	var selection_count: int = mini(3, valid_points.size())
	current_search_point = valid_points[randi() % selection_count]

	navigation_agent.target_position = (
		current_search_point.global_position
	)


func is_carrying_target() -> bool:
	return is_instance_valid(carried_item)


func drop_carried_item(direction: Vector3) -> void:
	if not is_instance_valid(carried_item):
		carried_item = null
		return

	var item: Item = carried_item
	carried_item = null
	item.drop(direction)

	item_dropped.emit(item)

# Tackle reaction

func receive_tackle(
	direction: Vector3,
	_attacker: Node3D
) -> void:
	if state == State.KNOCKED_DOWN:
		return

	drop_carried_item(direction)

	state = State.KNOCKED_DOWN
	knocked_down_remaining = knocked_down_time

	navigation_agent.target_position = global_position

	velocity.x = direction.x * knockback_speed
	velocity.z = direction.z * knockback_speed
	velocity.y = knockback_upward_speed

	knocked_down.emit()


func _update_knocked_down(delta: float) -> void:
	knocked_down_remaining -= delta

	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	if knocked_down_remaining <= 0.0 and is_on_floor():
		state = State.SEARCHING
		recovered.emit()
		_choose_search_point()


# Shared movement

func _follow_navigation(speed: float, delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		_slow_down(delta)
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_position - global_position
	direction.y = 0.0

	if direction.length_squared() <= 0.001:
		_slow_down(delta)
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

	_rotate_visuals(direction, delta)


func _slow_down(delta: float) -> void:
	velocity.x = move_toward(
		velocity.x,
		0.0,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		0.0,
		acceleration * delta
	)


func _rotate_visuals(
	direction: Vector3,
	delta: float
) -> void:
	var target_angle: float = atan2(-direction.x, -direction.z)

	visuals.rotation.y = lerp_angle(
		visuals.rotation.y,
		target_angle,
		rotation_speed * delta
	)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y <= 0.0:
		velocity.y = -0.5
	else:
		velocity.y -= gravity * delta
