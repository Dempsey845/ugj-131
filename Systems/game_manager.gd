class_name GameManager
extends Node

@export var announcement_manager: AnnouncementManager
@export var item_rounds: Array[ItemData]
@export var npc_manager: NPC_Manager
@export var slime_round: SlimeEnemyRound

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
		if index == 2 and is_instance_valid(slime_round):
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
	await get_tree().create_timer(5.0).timeout
	start_next_round.call_deferred()


func _finish_game() -> void:
	print("All rounds complete.")
