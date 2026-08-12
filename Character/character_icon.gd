class_name CharacterIcon
extends Control

@onready var head_texture: TextureRect = $HeadTexture

func set_head_color(color: Color):
    head_texture.modulate = color