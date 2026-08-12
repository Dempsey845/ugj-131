class_name SlimeEnemyRound
extends SpecialRound

@export_category("References")
@export var npc_manager: NPC_Manager
@export var player_score: Score
@export var player: Player
@export var door: Door

@export_category("Slimes")
@export var slime_container: Node3D
@export var slime_spawn_points: Array[Marker3D]
@export var slime_return_point: Marker3D

@export_category("State Checking")
@export var check_slime_state_rate: float = 1.0

var targets: Array[Node3D] = []
var active_slimes: Dictionary[int, WeakRef] = {}

var slime_state_timer: float = 0.0

var slime_scene: PackedScene = preload(
	"uid://d1sltvf53v71e"
)


func _physics_process(delta: float) -> void:
	if not is_round_active:
		return

	slime_state_timer += delta

	if slime_state_timer < check_slime_state_rate:
		return

	slime_state_timer = 0.0
	_update_active_slimes()

	if active_slimes.is_empty():
		end_round()


func _on_round_started() -> void:
	active_slimes.clear()
	slime_state_timer = 0.0

	get_targets()
	spawn_slimes()

	if active_slimes.is_empty():
		push_warning("No slimes were spawned.")
		end_round()


func _on_round_timeout() -> void:
	_return_all_slimes_home()


func _on_round_ended() -> void:
	active_slimes.clear()


func _update_active_slimes() -> void:
	for slime_id: int in active_slimes.keys():
		var slime: Enemy = _get_active_slime(slime_id)

		if not is_instance_valid(slime):
			active_slimes.erase(slime_id)
			continue

		var target: Node3D = slime.target

		if (
			not is_instance_valid(target)
			or get_target_points(target) <= 0
		):
			_return_slime_home(slime_id, slime)


func _return_all_slimes_home() -> void:
	for slime_id: int in active_slimes.keys():
		var slime: Enemy = _get_active_slime(slime_id)

		if not is_instance_valid(slime):
			active_slimes.erase(slime_id)
			continue

		_return_slime_home(slime_id, slime)

	await get_tree().create_timer(5.0).timeout
	door.close_door()


func _get_active_slime(slime_id: int) -> Enemy:
	var slime_reference: WeakRef = active_slimes.get(slime_id)

	if slime_reference == null:
		return null

	return slime_reference.get_ref() as Enemy


func _return_slime_home(
	slime_id: int,
	slime: Enemy
) -> void:
	active_slimes.erase(slime_id)

	if not is_instance_valid(slime_return_point):
		slime.queue_free()
		return

	slime.return_to_home(
		slime_return_point.global_position
	)


func get_targets() -> Array[Node3D]:
	targets.clear()

	if (
		is_instance_valid(player)
		and player_score.current_points > 0
	):
		targets.append(player)

	if is_instance_valid(npc_manager):
		for npc: NPC in npc_manager.npcs:
			if not is_instance_valid(npc):
				continue

			if get_target_points(npc) <= 0:
				continue

			targets.append(npc)

	targets.sort_custom(_sort_targets_by_points)
	return targets


func _sort_targets_by_points(
	target_a: Node3D,
	target_b: Node3D
) -> bool:
	return (
		get_target_points(target_a)
		> get_target_points(target_b)
	)


func get_target_points(target: Node3D) -> int:
	if not is_instance_valid(target):
		return 0

	if target == player:
		return player_score.current_points

	var score: Score = target.get_node_or_null("Score") as Score

	if score == null:
		return 0

	return score.current_points


func spawn_slimes() -> void:
	if targets.is_empty():
		push_warning(
			"Cannot spawn slimes because there are no valid targets."
		)
		return

	if not is_instance_valid(slime_container):
		push_warning("Slime container is not assigned.")
		return

	for index: int in slime_spawn_points.size():
		var spawn_point: Marker3D = slime_spawn_points[index]

		if not is_instance_valid(spawn_point):
			continue

		var slime: Enemy = slime_scene.instantiate() as Enemy

		slime_container.add_child(slime)
		slime.global_transform = spawn_point.global_transform

		var target_index: int = index % targets.size()
		slime.set_target(targets[target_index])

		active_slimes[slime.get_instance_id()] = weakref(slime)

	door.open_door()
