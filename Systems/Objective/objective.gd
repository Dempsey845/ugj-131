class_name Objective
extends Node

signal objective_started(item_data: ItemData)
signal objective_ended

const NEXT_ROUND_DELAY: float = 2.0
const HOT_POTATO_POSITION_POINTS: Array[int] = [10, 5, 2]
const NPC_POINT_MULTIPLIER: int = 2

@export_category("References")
@export var player_score: Score
@export var confetti_particles: ConfettiParticles
@export var hot_potato_manager: HotPotatoManager
@export var game_manager: GameManager
@export var npc_manager: NPC_Manager
@export var player: Player

@export_category("Spawn Bounds")
@export var top_left_bound: Marker3D
@export var top_right_bound: Marker3D

@export var spawn_vertical_tolerance: float = 1.0

@export_category("Item Spawning")
@export_flags_3d_navigation var spawn_navigation_layers: int = 1

@export var minimum_character_spawn_distance: float = 8.0

@export_range(1, 100, 1) var spawn_position_attempts: int = 30

@export var spawn_height_offset: float = 0.25

@onready var success_player: AudioStreamPlayer3D = $SuccessPlayer

var current_item: Item
var current_item_data: ItemData


func start_objective(item_data: ItemData) -> void:
	var spawn_position: Vector3 = _get_item_spawn_position()

	current_item_data = item_data
	current_item = item_data.item_scene.instantiate() as Item

	if not is_instance_valid(current_item):
		push_error("Objective could not instantiate the item.")
		current_item_data = null
		return

	add_child(current_item)
	current_item.global_position = (
		spawn_position
		+ Vector3.UP * spawn_height_offset
	)

	if current_item.is_item_hot_potato():
		hot_potato_manager.start()

	objective_started.emit(item_data)


func _get_item_spawn_position() -> Vector3:
	if not is_instance_valid(top_left_bound):
		push_error("Objective has no top-left spawn bound.")
		return player.global_position

	if not is_instance_valid(top_right_bound):
		push_error("Objective has no top-right spawn bound.")
		return player.global_position

	var navigation_map: RID = player.get_world_3d().navigation_map

	if not navigation_map.is_valid():
		push_error("Objective could not find a navigation map.")
		return player.global_position

	var characters: Array[Node3D] = _get_all_characters()

	var bound_a: Vector3 = top_left_bound.global_position
	var bound_b: Vector3 = top_right_bound.global_position

	var minimum_x: float = minf(bound_a.x, bound_b.x)
	var maximum_x: float = maxf(bound_a.x, bound_b.x)
	var minimum_z: float = minf(bound_a.z, bound_b.z)
	var maximum_z: float = maxf(bound_a.z, bound_b.z)

	var bounds_height: float = (
		bound_a.y + bound_b.y
	) * 0.5

	var best_position: Vector3 = player.global_position
	var best_clearance: float = -1.0
	var found_valid_position: bool = false

	for attempt: int in range(spawn_position_attempts):
		var random_position: Vector3 = Vector3(
			randf_range(minimum_x, maximum_x),
			bounds_height,
			randf_range(minimum_z, maximum_z)
		)

		# Project the generated position onto the navigation mesh.
		var candidate: Vector3 = (
			NavigationServer3D.map_get_closest_point(
				navigation_map,
				random_position
			)
		)

		if not _is_position_inside_spawn_bounds(
			candidate,
			minimum_x,
			maximum_x,
			minimum_z,
			maximum_z,
			bounds_height
		):
			continue

		found_valid_position = true

		var clearance: float = _get_distance_to_closest_character(
			candidate,
			characters
		)

		if clearance > best_clearance:
			best_clearance = clearance
			best_position = candidate

		if clearance >= minimum_character_spawn_distance:
			return candidate

	if not found_valid_position:
		push_warning(
			"Objective could not find a navigation point inside its bounds."
		)

	return best_position

func _is_position_inside_spawn_bounds(
	position: Vector3,
	minimum_x: float,
	maximum_x: float,
	minimum_z: float,
	maximum_z: float,
	bounds_height: float
) -> bool:
	var inside_horizontal_bounds: bool = (
		position.x >= minimum_x
		and position.x <= maximum_x
		and position.z >= minimum_z
		and position.z <= maximum_z
	)

	var inside_vertical_bounds: bool = (
		absf(position.y - bounds_height)
		<= spawn_vertical_tolerance
	)

	return inside_horizontal_bounds and inside_vertical_bounds

func _get_all_characters() -> Array[Node3D]:
	var characters: Array[Node3D] = []

	if is_instance_valid(player):
		characters.append(player)

	if is_instance_valid(npc_manager):
		for npc: NPC in npc_manager.npcs:
			if is_instance_valid(npc) and not npc.is_queued_for_deletion():
				characters.append(npc)

	return characters


func _get_distance_to_closest_character(
	position: Vector3,
	characters: Array[Node3D]
) -> float:
	if characters.is_empty():
		return INF

	var closest_distance_squared: float = INF

	for character: Node3D in characters:
		# Horizontal distance is usually more appropriate for spawn placement.
		var difference: Vector3 = (
			position - character.global_position
		)
		difference.y = 0.0

		closest_distance_squared = minf(
			closest_distance_squared,
			difference.length_squared()
		)

	return sqrt(closest_distance_squared)


func stop_objective() -> void:
	objective_ended.emit()

	if is_instance_valid(current_item):
		if current_item.is_item_hot_potato():
			_finish_hot_potato_objective()
		else:
			_finish_standard_objective()

		current_item.queue_free()

	current_item = null
	current_item_data = null

	await get_tree().create_timer(NEXT_ROUND_DELAY).timeout
	game_manager.start_next_round()


func _finish_standard_objective() -> void:
	var current_carrier: Node3D = current_item.carrier
	var last_carrier: Node3D = current_item.last_carrier

	var has_current_carrier: bool = is_instance_valid(
		current_carrier
	)
	var has_last_carrier: bool = is_instance_valid(
		last_carrier
	)

	if not has_current_carrier and not has_last_carrier:
		return

	var reward_recipient: Node3D
	var base_reward_amount: int

	if has_current_carrier:
		reward_recipient = current_carrier
		base_reward_amount = current_item_data.points_reward
	else:
		reward_recipient = _get_last_carrier_reward_recipient(
			last_carrier
		)

		base_reward_amount = int(
			float(current_item_data.points_reward) / 2.0
		)

	if not is_instance_valid(reward_recipient):
		return

	_reward_character(
		reward_recipient,
		base_reward_amount
	)

	_play_confetti(reward_recipient.global_position)


func _get_last_carrier_reward_recipient(
	last_carrier: Node3D
) -> Node3D:
	if not is_instance_valid(last_carrier):
		return null

	var last_tackler: Node3D = last_carrier.tackler

	if is_instance_valid(last_tackler):
		return last_tackler

	return last_carrier


func _finish_hot_potato_objective() -> void:
	hot_potato_manager.end()

	var carrier: Node3D = _get_item_carrier_or_last_carrier()

	if is_instance_valid(carrier):
		_reset_carrier_item_time(carrier)

	var top_players: Array[Node3D] = (
		hot_potato_manager.get_top_three_players()
	)

	_reward_top_hot_potato_players(top_players)

	if not top_players.is_empty():
		_play_confetti(top_players[0].global_position)


func _get_item_carrier_or_last_carrier() -> Node3D:
	if is_instance_valid(current_item.carrier):
		return current_item.carrier

	if is_instance_valid(current_item.last_carrier):
		return current_item.last_carrier

	return null


func _get_character_score(character: Node3D) -> Score:
	if character is Player:
		return player_score

	if character is NPC:
		return character.get_node_or_null("Score") as Score

	return null


func _reward_top_hot_potato_players(
	top_players: Array[Node3D]
) -> void:
	var rewarded_player_count: int = mini(
		top_players.size(),
		HOT_POTATO_POSITION_POINTS.size()
	)

	for index: int in range(rewarded_player_count):
		var character: Node3D = top_players[index]

		if not is_instance_valid(character):
			continue

		_reward_character(
			character,
			HOT_POTATO_POSITION_POINTS[index]
		)

func _reward_character(
	character: Node3D,
	base_points: int
) -> void:
	if not is_instance_valid(character):
		return

	var score: Score = _get_character_score(character)

	if not is_instance_valid(score):
		return

	var point_multiplier: int = 1

	if character is NPC:
		point_multiplier = NPC_POINT_MULTIPLIER

	score.add_points(base_points * point_multiplier)

func _reset_carrier_item_time(carrier: Node3D) -> void:
	if carrier is NPC:
		var npc: NPC = carrier

		hot_potato_manager.reset_player_hold_second(
			&"npc_%s" % npc.assigned_name.to_lower()
		)

	elif carrier is Player:
		hot_potato_manager.reset_player_hold_second(
			&"player"
		)


func _play_confetti(position: Vector3) -> void:
	success_player.global_position = position
	success_player.play()
	confetti_particles.global_position = position
	confetti_particles.explode()