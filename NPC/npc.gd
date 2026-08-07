class_name NPC
extends CharacterBody3D

signal knocked_down
signal recovered
signal item_dropped(item: Node3D)
signal item_picked_up

enum State {
	SEARCHING,
	CHASING,
	SLIDING,
	CARRYING,
	KNOCKED_DOWN
}


@export_category("References")
@export var visuals: Node3D
@export var navigation_agent: NavigationAgent3D
@export var item_holder: Marker3D
@export var search_points: Array[Node3D]
@export var player: Player
@export var slide_hitbox: Area3D


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

@export_category("NPC Slide Tackle")
@export var slide_speed: float = 11.0
@export var slide_duration: float = 1.2
@export var slide_deceleration: float = 8.0
@export var slide_steering: float = 1.5
@export var tackle_start_distance: float = 4.0
@export var tackle_cooldown: float = 3.5
@export_range(0.0, 1.0) var tackle_chance: float = 0.75

@export_category("Chasing")
@export var maximum_chase_distance: float = 20.0
@export var item_pickup_distance: float = 1.25

var state: State = State.SEARCHING
var chase_target: Node3D
var carried_item: Item
var chased_item: Item

var current_search_point: Node3D
var is_waiting: bool = false
var knocked_down_remaining: float = 0.0

var is_sliding: bool = false
var slide_direction: Vector3
var current_slide_speed: float = 0.0
var slide_time_remaining: float = 0.0
var tackle_cooldown_remaining: float = 0.0
var slide_target: Node3D

var slide_hit_targets: Array[Node3D] = []

func _ready() -> void:
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 1.0

	slide_hitbox.monitoring = false
	slide_hitbox.body_entered.connect(
		_on_slide_hitbox_body_entered
	)

	call_deferred("_choose_search_point")


func _physics_process(delta: float) -> void:
	tackle_cooldown_remaining = maxf(
		tackle_cooldown_remaining - delta,
		0.0
	)

	_apply_gravity(delta)

	match state:
		State.SEARCHING:
			_update_searching(delta)

		State.CHASING:
			_update_chasing(delta)

		State.SLIDING:
			_update_slide(delta)

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

func chase_dropped_item(item: Item) -> void:
	if not is_instance_valid(item):
		return

	_stop_tracking_chased_item()

	chased_item = item
	chase_target = item

	if not item.picked_up.is_connected(
		_on_chased_item_picked_up
	):
		item.picked_up.connect(
			_on_chased_item_picked_up
	)

	if not item.tree_exiting.is_connected(
		_on_chased_item_removed
	):
		item.tree_exiting.connect(
			_on_chased_item_removed
	)

	if state != State.KNOCKED_DOWN:
		state = State.CHASING

func _update_chasing(delta: float) -> void:
	if not is_instance_valid(chase_target):
		stop_chasing()
		return

	var distance_to_target: float = global_position.distance_to(
		chase_target.global_position
	)

	if distance_to_target > maximum_chase_distance:
		stop_chasing()
		return

	if chase_target == chased_item:
		if distance_to_target <= item_pickup_distance:
			_slow_down(delta)
			return

	# The target is another character carrying the item.
	elif (
		distance_to_target <= tackle_start_distance
		and tackle_cooldown_remaining <= 0.0
		and chase_target.has_method("receive_tackle")
	):
		# The chance stops every NPC from tackling at exactly
		# the same moment whenever they reach the carrier.
		if randf() <= tackle_chance:
			_start_slide_tackle(chase_target)
			return
		else:
			# Briefly prevent another chance roll every frame.
			tackle_cooldown_remaining = 0.4

	navigation_agent.target_position = chase_target.global_position
	_follow_navigation(move_speed, delta)


func stop_chasing() -> void:
	chase_target = null
	_stop_tracking_chased_item()

	if state == State.KNOCKED_DOWN:
		return

	state = State.SEARCHING
	_choose_search_point()


func _on_chased_item_picked_up(carrier: Node3D) -> void:
	if not is_instance_valid(carrier):
		stop_chasing()
		return

	if carrier == self:
		return

	chase_target = carrier

	if state != State.KNOCKED_DOWN:
		state = State.CHASING

func _on_chased_item_removed() -> void:
	chased_item = null
	chase_target = null

	if state != State.KNOCKED_DOWN:
		state = State.SEARCHING
		_choose_search_point()

func _stop_tracking_chased_item() -> void:
	if not is_instance_valid(chased_item):
		chased_item = null
		return

	if chased_item.picked_up.is_connected(
		_on_chased_item_picked_up
	):
		chased_item.picked_up.disconnect(
			_on_chased_item_picked_up
	)

	if chased_item.tree_exiting.is_connected(
		_on_chased_item_removed
	):
		chased_item.tree_exiting.disconnect(
			_on_chased_item_removed
	)

	chased_item = null

# Sliding

func _start_slide_tackle(target: Node3D) -> void:
	if state == State.KNOCKED_DOWN:
		return

	if not is_instance_valid(target):
		return

	slide_target = target

	slide_direction = target.global_position - global_position
	slide_direction.y = 0.0

	if slide_direction.length_squared() <= 0.001:
		return

	slide_direction = slide_direction.normalized()

	state = State.SLIDING
	is_sliding = true
	slide_time_remaining = slide_duration
	current_slide_speed = slide_speed

	slide_hit_targets.clear()
	slide_hitbox.set_deferred("monitoring", true)

	_rotate_visuals(slide_direction, 1.0)


func _update_slide(delta: float) -> void:
	slide_time_remaining -= delta

	# Give the NPC a small amount of steering toward its target.
	if is_instance_valid(slide_target):
		var target_direction := (
			slide_target.global_position - global_position
		)
		target_direction.y = 0.0

		if target_direction.length_squared() > 0.001:
			target_direction = target_direction.normalized()

			slide_direction = slide_direction.move_toward(
				target_direction,
				slide_steering * delta
			).normalized()

	current_slide_speed = move_toward(
		current_slide_speed,
		0.0,
		slide_deceleration * delta
	)

	velocity.x = slide_direction.x * current_slide_speed
	velocity.z = slide_direction.z * current_slide_speed

	_rotate_visuals(slide_direction, delta)

	if (
		slide_time_remaining <= 0.0
		or current_slide_speed <= move_speed
		or not is_on_floor()
	):
		_end_slide_tackle()


func _end_slide_tackle() -> void:
	if not is_sliding:
		return

	is_sliding = false
	slide_target = null
	tackle_cooldown_remaining = tackle_cooldown

	slide_hitbox.set_deferred("monitoring", false)

	if is_instance_valid(chase_target):
		state = State.CHASING
	else:
		state = State.SEARCHING
		_choose_search_point()

func _on_slide_hitbox_body_entered(body: Node3D) -> void:
	if state != State.SLIDING:
		return

	if body == self:
		return

	if body in slide_hit_targets:
		return

	if not body.has_method("receive_tackle"):
		return

	slide_hit_targets.append(body)

	body.receive_tackle(slide_direction, self)

	# End after the first valid character is hit.
	_end_slide_tackle()

# Carrying and fleeing

func collect_item(item: Item) -> void:
	if not is_instance_valid(item):
		return

	if is_instance_valid(carried_item):
		return

	if item.collect(self, item_holder):
		carried_item = item
		chase_target = null
		item_picked_up.emit()

		if chased_item == item:
			_stop_tracking_chased_item()

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

	var item: Item = carried_item
	drop_carried_item(direction)
	if is_instance_valid(item):
		chase_dropped_item(item)

	state = State.KNOCKED_DOWN
	knocked_down_remaining = knocked_down_time

	navigation_agent.target_position = global_position

	velocity.x = direction.x * knockback_speed
	velocity.z = direction.z * knockback_speed
	velocity.y = knockback_upward_speed

	knocked_down.emit()


func _update_knocked_down(delta: float) -> void:
	knocked_down_remaining -= delta

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

	if knocked_down_remaining > 0.0 or not is_on_floor():
		return

	recovered.emit()

	if is_instance_valid(chase_target):
		state = State.CHASING
	elif is_instance_valid(carried_item):
		state = State.CARRYING
		_choose_flee_point()
	else:
		state = State.SEARCHING
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
