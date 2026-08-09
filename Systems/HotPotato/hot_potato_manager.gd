class_name HotPotatoManager
extends Node

@export var leaderboard_ui: LeaderboardUI
@export var npc_manager: NPC_Manager

var player_hold_seconds: Dictionary[StringName, float]

var player_id_to_name: Dictionary[StringName, String]

func _ready() -> void:
	await get_tree().process_frame

	for npc: NPC in npc_manager.npcs:
		var npc_id: StringName = &"npc_%s" % npc.assigned_name.to_lower()
		leaderboard_ui.add_player(
		npc_id,
		npc.assigned_name,
		load("res://icon.svg")
		)

		player_hold_seconds[npc_id] = 0
		player_id_to_name[npc_id] = npc.assigned_name

	leaderboard_ui.add_player(
		&"player",
		SceneManager.player_name,
		load("res://icon.svg")
	)

	player_hold_seconds[&"player"] = 0
	player_id_to_name[&"player"] = SceneManager.player_name

func increment_player_hold_second(player_id: StringName, increment: float = 0.1):
	player_hold_seconds[player_id] += increment

	leaderboard_ui.set_player_time(
		player_id,
		player_id_to_name[player_id],
		player_hold_seconds[player_id],
		load("res://icon.svg")
	)
