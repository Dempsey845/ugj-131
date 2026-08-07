class_name GameManager
extends Node

@export var announcement_manager: AnnouncementManager
@export var start_item_data: ItemData

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	announcement_manager.start_announcement(start_item_data)
