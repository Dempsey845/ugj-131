extends Node

var player_name: String = "Player"

var top_three: Array[Dictionary] # name, base_color, shoe_color

func sign_up(sign_up_name: String):
    player_name = sign_up_name

    TransitionUi.change_scene("uid://iuwi8d7umvdk", "Are you ready?")
