class_name GameManager
extends Node

signal round_started

@export var announcement_manager: AnnouncementManager
@export var item_rounds: Array[ItemData]
@export var npc_manager: NPC_Manager
@export var slime_round: SlimeEnemyRound
@export var player_score: Score
@export var player: Player

var is_current_round_hot_potato: bool = false
var round_time: float = 0.0
var urgent_time: float = 20.0

var current_round: int = 0
var item_rounds_started: int = 0

var current_item_data: ItemData
var rounds: Array = []


func _ready() -> void:
	_build_round_list()

	await get_tree().create_timer(2.0).timeout
	start_next_round()


func _build_round_list() -> void:
	rounds.clear()

	for index: int in item_rounds.size():
		if index == 4 and is_instance_valid(slime_round):
			rounds.append(slime_round)

		rounds.append(item_rounds[index])


func start_next_round() -> void:
	if current_round >= rounds.size():
		_finish_game()
		return

	var next_round: Variant = rounds[current_round]
	current_round += 1

	if next_round is ItemData:
		_start_item_round(next_round as ItemData)

	elif next_round is SpecialRound:
		_start_special_round(next_round as SpecialRound)

	else:
		push_warning(
			"Unsupported round type at index %s."
			% (current_round - 1)
		)

		start_next_round.call_deferred()
		return
	
	round_started.emit()

func get_top_three_players() -> Array[Node3D]:
	var scored_players: Array[Dictionary] = []
	var zero_point_players: Array[Node3D] = []

	if is_instance_valid(player):
		if player_score.current_points > 0:
			scored_players.append({
				"player": player,
				"points": player_score.current_points
			})
		else:
			zero_point_players.append(player)

	for npc: NPC in npc_manager.npcs:
		if not is_instance_valid(npc):
			continue

		var score := npc.get_node_or_null("Score") as Score

		if not is_instance_valid(score):
			push_warning(
				"NPC %s does not have a Score node." % npc.name
			)
			continue

		if score.current_points > 0:
			scored_players.append({
				"player": npc,
				"points": score.current_points
			})
		else:
			zero_point_players.append(npc)

	scored_players.shuffle()

	scored_players.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return first["points"] > second["points"]
	)

	zero_point_players.shuffle()

	var top_three: Array[Node3D] = []

	for entry: Dictionary in scored_players:
		top_three.append(entry["player"] as Node3D)

		if top_three.size() == 3:
			return top_three

	# Fill empty podium positions with random zero-point contestants.
	for contestant: Node3D in zero_point_players:
		top_three.append(contestant)

		if top_three.size() == 3:
			break

	return top_three

func _start_item_round(item_data: ItemData) -> void:
	current_item_data = item_data
	item_rounds_started += 1

	announcement_manager.start_announcement(item_data)

	if item_rounds_started > 1:
		npc_manager.spawn_npcs()


func _start_special_round(special_round: SpecialRound) -> void:
	is_current_round_hot_potato = false
	current_item_data = null

	if not special_round.round_ended.is_connected(
		_on_special_round_ended
	):
		special_round.round_ended.connect(
			_on_special_round_ended,
			CONNECT_ONE_SHOT
		)

	special_round.start_round()


func _on_special_round_ended() -> void:
	await get_tree().create_timer(2.0).timeout
	start_next_round.call_deferred()


func _finish_game() -> void:
	SceneManager.top_three.clear()

	var top_three_players: Array[Node3D] = get_top_three_players()
	var top_three: Array[Dictionary]

	for top in top_three_players:
		var player_name: String = ""
		if top is NPC:
			player_name = top.assigned_name
		elif top is Player:
			player_name = SceneManager.player_name
		
		var character: Character = top.get_node("%Character")

		top_three.append({
			"name": player_name,
			"base_color": character.color,
			"shoe_color": character.shoe_color
		})

	SceneManager.top_three = top_three


	TransitionUi.change_scene("res://Victory/victory_scene.tscn", "Let's see who won!")
