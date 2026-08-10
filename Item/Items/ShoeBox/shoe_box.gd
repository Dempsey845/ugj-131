class_name ShoeBox
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func open_lid():
    animation_player.play_backwards("close_lid")

func close_lid():
    animation_player.play("close_lid")