class_name SlimeEnemyRound
extends Node


@export var npc_manager: NPC_Manager
@export var player_score: Score
@export var player: Player
@export var countdown_ui: CountdownUI

@export var round_duration: int = 30
@export var slime_container: Node3D
@export var slime_spawn_points: Array[Marker3D]

@export var slime_return_point: Marker3D

var targets: Array[Node3D] = []

var active_slimes: Dictionary[int, WeakRef] = {}

var slime_scene: PackedScene = preload("uid://d1sltvf53v71e")

var round_started: bool

var check_slime_state_rate: float = 1.0
var slime_state_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not round_started:
		return

	slime_state_timer += delta

	if slime_state_timer < check_slime_state_rate:
		return

	slime_state_timer = 0.0

	for slime_id: int in active_slimes.keys():
		var slime_reference: WeakRef = active_slimes[slime_id]
		var slime: Enemy = slime_reference.get_ref() as Enemy

		if not is_instance_valid(slime):
			active_slimes.erase(slime_id)
			continue

		var target: Node3D = slime.target

		if not is_instance_valid(target):
			_return_slime_home(slime_id, slime)
			continue

		if get_target_points(target) <= 0:
			_return_slime_home(slime_id, slime)

	if active_slimes.is_empty():
		end_slime_round()


func _return_slime_home(
	slime_id: int,
	slime: Enemy
) -> void:
	active_slimes.erase(slime_id)

	slime.return_to_home(
		slime_return_point.global_position
	)

func start_slime_round() -> void:
	active_slimes.clear()
	slime_state_timer = 0.0

	countdown_ui.start_countdown(round_duration)
	if not countdown_ui.countdown_finished.is_connected(_on_countdown_finished):
		countdown_ui.countdown_finished.connect(_on_countdown_finished)

	get_targets()
	spawn_slimes()

func end_slime_round():
	if !round_started:
		return
	
	if countdown_ui.countdown_finished.is_connected(_on_countdown_finished):
		countdown_ui.countdown_finished.disconnect(_on_countdown_finished)

	countdown_ui.stop_countdown()

	round_started = false

func get_targets() -> Array[Node3D]:
	targets.clear()

	if (
		is_instance_valid(player)
		and player_score.current_points > 0
	):
		targets.append(player)

	for npc: NPC in npc_manager.npcs:
		if not is_instance_valid(npc):
			continue

		var score: Score = npc.get_node_or_null("Score") as Score

		if score == null or score.current_points <= 0:
			continue

		targets.append(npc)

	targets.sort_custom(_sort_targets_by_points)

	return targets


func _sort_targets_by_points(
	target_a: Node3D,
	target_b: Node3D
) -> bool:
	return get_target_points(target_a) > get_target_points(target_b)


func get_target_points(target: Node3D) -> int:
	if target == player:
		return player_score.current_points

	var score: Score = target.get_node_or_null("Score")

	if score == null:
		return 0

	return score.current_points

func spawn_slimes() -> void:
	if targets.is_empty():
		push_warning(
			"Cannot spawn slimes because there are no targets with points."
		)
		return

	if not is_instance_valid(slime_container):
		push_warning("Slime container is not assigned.")
		return

	for i: int in slime_spawn_points.size():
		var spawn_point: Marker3D = slime_spawn_points[i]

		if not is_instance_valid(spawn_point):
			continue

		var slime: Enemy = slime_scene.instantiate()

		slime_container.add_child(slime)
		slime.global_transform = spawn_point.global_transform

		# Cycles evenly through every available target.
		var target_index: int = i % targets.size()
		var assigned_target: Node3D = targets[target_index]

		slime.set_target(assigned_target)

		active_slimes[slime.get_instance_id()] = weakref(slime)
	
	round_started = true

func _on_countdown_finished() -> void:
	if not round_started:
		return

	for slime_id: int in active_slimes.keys():
		var slime_reference: WeakRef = active_slimes[slime_id]
		var slime: Enemy = slime_reference.get_ref() as Enemy

		if not is_instance_valid(slime):
			active_slimes.erase(slime_id)
			continue

		_return_slime_home(slime_id, slime)

	end_slime_round()