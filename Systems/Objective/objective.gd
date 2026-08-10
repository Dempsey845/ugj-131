class_name Objective
extends Node

signal objective_started(item_data: ItemData)
signal objective_ended

@export var item_spawn_points: Array[Marker3D]
@export var player_score: Score
@export var confetti_particles: ConfettiParticles
@export var hot_potato_manager: HotPotatoManager
@export var game_manager: GameManager

var current_item: Item
var current_item_data: ItemData

func start_objective(item_data: ItemData):
	var spawn_point: Marker3D = item_spawn_points.pick_random()
	
	current_item = item_data.item_scene.instantiate()
	spawn_point.add_child(current_item)

	current_item_data = item_data

	if current_item.has_node("HotPotatoItemAgent"):
		hot_potato_manager.start()
	
	objective_started.emit(item_data)

func stop_objective():
	objective_ended.emit()

	if is_instance_valid(current_item):
		var show_confetti: bool
		var confetti_position: Vector3

		if current_item.has_node("HotPotatoItemAgent"):
			hot_potato_manager.end()

		if current_item.carrier:
			if current_item.is_item_hot_potato():
				_reset_carrier_item_time(current_item.carrier)

				var top_players: Array[Node3D] = hot_potato_manager.get_top_three_players()
				_reward_top_hot_potato_players(top_players)

				if top_players.size() > 0:
					confetti_position = top_players[0].global_position
					show_confetti = true
			else:
				var carrier_score: Score = player_score

				if current_item.carrier is NPC:
					carrier_score = current_item.carrier.get_node("Score")

				carrier_score.add_points(current_item_data.points_reward)

				show_confetti = true
				confetti_position = current_item.carrier.global_position
		else:
			if current_item.is_item_hot_potato():
				var top_players: Array[Node3D] = hot_potato_manager.get_top_three_players()
				_reward_top_hot_potato_players(top_players)

				if top_players.size() > 0:
					confetti_position = top_players[0].global_position
					show_confetti = true

		if show_confetti:
				confetti_particles.global_position = confetti_position
				confetti_particles.explode()
		current_item.queue_free()
		
	current_item = null

	await get_tree().create_timer(2.0).timeout
	game_manager.start_next_round()

func _reward_top_hot_potato_players(top_players: Array[Node3D]):
	const POSITION_POINTS = [10, 5, 2]

	for i in range(top_players.size()):
		var t_player: Node3D = top_players[i]
		if t_player is NPC:
			var npc_score: Score = t_player.get_node("Score")
			npc_score.add_points(POSITION_POINTS[i])
		elif t_player is Player:
			player_score.add_points(POSITION_POINTS[i])

func _reset_carrier_item_time(carrier: Node3D):
	# Reset the carrier who is holding the potato to 0 time
	if carrier is NPC:
		var npc: NPC = carrier
		hot_potato_manager.reset_player_hold_second(
			&"npc_%s" % npc.assigned_name.to_lower()
		)
	
	elif carrier is Player:
		hot_potato_manager.reset_player_hold_second(
			&"player"
		)
