class_name HotPotatoManager
extends Node

signal player_time_reset(player_id: StringName, time_lossed: float)

@export var leaderboard_ui: LeaderboardUI
@export var npc_manager: NPC_Manager
@export var player: Player

var player_hold_seconds: Dictionary[StringName, float]

var player_id_to_name: Dictionary[StringName, String]

var player_id_to_instance: Dictionary[StringName, Node3D]

func _ready() -> void:
	await get_tree().process_frame

	for npc: NPC in npc_manager.npcs:
		register_npc(npc)

	npc_manager.npcs_created.connect(_on_npcs_created)

	leaderboard_ui.add_player(
		&"player",
		SceneManager.player_name,
		load("res://icon.svg")
	)

	player_hold_seconds[&"player"] = 0
	player_id_to_name[&"player"] = SceneManager.player_name
	player_id_to_instance[&"player"] = player

func set_player_hold_second(player_id: StringName, value: float):
	player_hold_seconds[player_id] = value

	leaderboard_ui.set_player_time(
		player_id,
		player_id_to_name[player_id],
		player_hold_seconds[player_id],
		load("res://icon.svg")
	)

func reset_player_hold_second(player_id: StringName):
	player_time_reset.emit(player_id, player_hold_seconds[player_id])
	set_player_hold_second(player_id, 0.0)

func increment_player_hold_second(player_id: StringName, increment: float = 0.1):
	set_player_hold_second(player_id, player_hold_seconds[player_id] + increment)

func get_top_three_players() -> Array[Node3D]:
	var ranked_ids: Array[StringName] = []

	for player_id: StringName in player_hold_seconds:
		if player_hold_seconds[player_id] > 0.0:
			ranked_ids.append(player_id)

	ranked_ids.sort_custom(
		func(a: StringName, b: StringName) -> bool:
			return (
				player_hold_seconds[a]
				> player_hold_seconds[b]
			)
	)

	var top_players: Array[Node3D] = []

	for player_id: StringName in ranked_ids:
		var instance: Node3D = player_id_to_instance.get(
			player_id
		)

		if is_instance_valid(instance):
			top_players.append(instance)

		if top_players.size() >= 3:
			break

	return top_players

func register_npc(npc: NPC):
	var npc_id: StringName = &"npc_%s" % npc.assigned_name.to_lower()
	leaderboard_ui.add_player(
	npc_id,
	npc.assigned_name,
	load("res://icon.svg")
	)

	player_hold_seconds[npc_id] = 0
	player_id_to_name[npc_id] = npc.assigned_name
	player_id_to_instance[npc_id] = npc

func _on_npcs_created(npcs: Array[NPC]):
	for npc in npcs:
		register_npc(npc)
