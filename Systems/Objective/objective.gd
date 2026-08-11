class_name Objective
extends Node

signal objective_started(item_data: ItemData)
signal objective_ended

const NEXT_ROUND_DELAY: float = 2.0
const HOT_POTATO_POSITION_POINTS: Array[int] = [10, 5, 2]

@export_category("References")
@export var item_spawn_points: Array[Marker3D]
@export var player_score: Score
@export var confetti_particles: ConfettiParticles
@export var hot_potato_manager: HotPotatoManager
@export var game_manager: GameManager

var current_item: Item
var current_item_data: ItemData


func start_objective(item_data: ItemData) -> void:
	if item_spawn_points.is_empty():
		push_error("Objective has no item spawn points.")
		return

	current_item_data = item_data

	var spawn_point: Marker3D = item_spawn_points.pick_random()

	current_item = item_data.item_scene.instantiate() as Item
	spawn_point.add_child(current_item)

	if current_item.is_item_hot_potato():
		hot_potato_manager.start()

	objective_started.emit(item_data)


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

	var has_current_carrier: bool = is_instance_valid(current_carrier)
	var has_last_carrier: bool = is_instance_valid(last_carrier)

	if not has_current_carrier and not has_last_carrier:
		return

	var reward_recipient: Node3D
	var reward_amount: int

	if has_current_carrier:
		reward_recipient = current_carrier
		reward_amount = current_item_data.points_reward
	else:
		reward_recipient = _get_last_carrier_reward_recipient(
			last_carrier
		)

		reward_amount = int(
			float(current_item_data.points_reward) / 2.0
		)

	if not is_instance_valid(reward_recipient):
		return

	var score: Score = _get_character_score(reward_recipient)

	if is_instance_valid(score):
		score.add_points(reward_amount)

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

		var score: Score = _get_character_score(character)

		if is_instance_valid(score):
			score.add_points(
				HOT_POTATO_POSITION_POINTS[index]
			)


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
	confetti_particles.global_position = position
	confetti_particles.explode()