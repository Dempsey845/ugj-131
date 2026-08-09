extends Node

var world_scene: PackedScene = preload("uid://iuwi8d7umvdk")

var player_name: String

func sign_up(sign_up_name: String):
    player_name = sign_up_name

    get_tree().change_scene_to_packed(world_scene)
