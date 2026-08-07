class_name NPC_ItemDetector
extends Area3D

@onready var search_timer: Timer = $SearchTimer

@onready var npc: NPC = get_parent()

func _ready() -> void:
	search_timer.timeout.connect(_on_search_timer_timeout)

func search_for_item():
	var overlapping_areas: Array[Area3D] = get_overlapping_areas()
	for area: Area3D in overlapping_areas:
		if area.get_parent() is not Item:
			continue
		
		npc.collect_item(area.get_parent() as Item)
		break

func _on_search_timer_timeout():
	search_for_item()