class_name SlimeEnemyRound
extends Node


@export var npc_manager: NPC_Manager
@export var player_score: Score
@export var player: Player

@export var slime_container: Node3D
@export var slime_spawn_points: Array[Marker3D]

@export var slime_return_point: Marker3D

var targets: Array[Node3D] = []

var active_slimes: Dictionary[Enemy, bool]

var slime_scene: PackedScene = preload("uid://d1sltvf53v71e")

var round_started: bool

var check_slime_state_rate: float = 1.0
var slime_state_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if !round_started:
		return
	
	slime_state_timer += delta

	if slime_state_timer > check_slime_state_rate:
		slime_state_timer = 0.0

		var non_active_slime_count: int = 0

		for slime: Enemy in active_slimes:
			if !is_instance_valid(slime):
				non_active_slime_count += 1
				continue

			if !active_slimes[slime]:
				non_active_slime_count += 1
				continue
			
			var target: Node3D = slime.target

			if target is NPC:
				var npc_score: Score = target.get_node("Score")
				if npc_score.current_points <= 0:
					slime.return_to_home(slime_return_point.global_position)
					active_slimes[slime] = false
			elif target is Player and player_score.current_points <= 0:
				slime.return_to_home(slime_return_point.global_position)
				active_slimes[slime] = false
		
		if non_active_slime_count >= active_slimes.keys().size():
			# All slimes have died or returned home
			end_slime_round()


func start_slime_round():
	get_targets()
	spawn_slimes()

func end_slime_round():
	if !round_started:
		return
	
	print("Slime round complete.")

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

		active_slimes[slime] = true
	
	round_started = true
