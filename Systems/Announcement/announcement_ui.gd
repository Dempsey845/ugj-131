class_name AnnouncementUI
extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    await get_tree().create_timer(2.0).timeout
    show_announcement()

func show_announcement(duration: float = 3.0):
    animation_player.play("show_announcement")
    await animation_player.animation_finished
    await get_tree().create_timer(duration).timeout
    animation_player.play_backwards("show_announcement")
