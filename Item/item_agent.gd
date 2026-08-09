class_name ItemAgent
extends Node

@onready var item: Item = get_parent()

var game_manager: GameManager

var affected_carrier: Node3D

func _ready() -> void:
	game_manager = get_tree().current_scene.get_node("GameManager")
	game_manager.is_current_round_hot_potato = false

	item.picked_up.connect(_on_item_picked_up)
	item.dropped.connect(_on_item_dropped)


func _exit_tree() -> void:
	reset_effect()

func reset_effect():
	pass

func _on_item_picked_up(carrier):
	affected_carrier = carrier

func _on_item_dropped():
	affected_carrier = null