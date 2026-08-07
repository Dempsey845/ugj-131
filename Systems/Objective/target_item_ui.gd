extends Control

@export var objective: Objective

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var name_label: Label = %NameLabel
@onready var icon_texture: TextureRect = %IconTexture

func _ready() -> void:
	objective.objective_started.connect(_on_objective_started)
	objective.objective_ended.connect(_on_objective_ended)

func show_target_item(item_data: ItemData):
	name_label.text = item_data.item_name
	icon_texture.texture = item_data.item_texture
	animation_player.play("pop_in")
	
func hide_target_item():
	animation_player.play_backwards("pop_in")

func _on_objective_started(item_data: ItemData):
	show_target_item(item_data)

func _on_objective_ended():
	hide_target_item()