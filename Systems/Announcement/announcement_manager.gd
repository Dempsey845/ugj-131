class_name AnnouncementManager
extends Node

signal announcement_started(announcement: String, icon: Texture, duration: float)

@export var objective: Objective

var current_item_data: ItemData

func start_announcement(item_data: ItemData, duration: float = 3.0):
	announcement_started.emit(
		"Announcement: A %s has been hidden! Have it when the time is up and it's yours!" % sanitize_string(item_data.item_name),
		item_data.item_texture,
		duration
	)
	
	current_item_data = item_data
	
func stop_announcement():
	if current_item_data == null:
		return
	objective.start_objective(current_item_data)
	current_item_data = null
	
func sanitize_string(text: String) -> String:
	var regex := RegEx.new()
	regex.compile("[^a-zA-Z0-9 ]")

	return regex.sub(text, "", true).to_lower()
