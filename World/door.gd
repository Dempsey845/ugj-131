class_name Door
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func open_door():
    animation_player.play("open")

func close_door():
    animation_player.play_backwards("open")