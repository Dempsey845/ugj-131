class_name AnnouncementUI
extends Control

@export var announcement_manager: AnnouncementManager

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = %Label
@onready var icon_texture: TextureRect = %IconTexture

func _ready():
	announcement_manager.announcement_started.connect(_on_announcement_started)

func _on_announcement_started(announcement: String, icon: Texture, duration: float):
	_show_announcement(announcement, icon, duration)

func _show_announcement(announcement: String, icon: Texture, duration: float):
	label.text = announcement
	icon_texture.texture = icon
	
	animation_player.play("show_announcement")
	await animation_player.animation_finished
	
	await get_tree().create_timer(duration).timeout
	
	animation_player.play_backwards("show_announcement")
	await animation_player.animation_finished
	announcement_manager.stop_announcement()
