class_name GameManager
extends Node

@export var announcement_manager: AnnouncementManager
@export var start_item_data: ItemData

var is_current_round_hot_potato: bool
var round_time: float
var urgent_time: float = 30.0

var current_item_data: ItemData

func _ready() -> void:
	current_item_data = start_item_data
	await get_tree().create_timer(2.0).timeout
	announcement_manager.start_announcement(start_item_data)
