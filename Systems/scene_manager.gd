extends Node

var player_name: String = "Player"

func sign_up(sign_up_name: String):
    player_name = sign_up_name

    TransitionUi.change_scene("uid://iuwi8d7umvdk", "Are you ready?")
