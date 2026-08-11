class_name GameManager
extends Node

@export var announcement_manager: AnnouncementManager
@export var rounds: Array[ItemData]
@export var npc_manager: NPC_Manager
@export var slime_round: SlimeEnemyRound

var is_current_round_hot_potato: bool
var round_time: float
var urgent_time: float = 20.0

var current_round: int

var current_item_data: ItemData

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	start_next_round()

func start_next_round():
	if current_round == rounds.size():
		return

	current_round += 1

	if current_round == 3:
		slime_round.start_slime_round()
		return

	current_item_data = rounds[current_round - 1]
	announcement_manager.start_announcement(current_item_data)
	if current_round > 1:
		npc_manager.spawn_npcs()
