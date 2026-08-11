extends Node

@onready var enemy: Enemy = get_parent()
@onready var slime_visual: SlimeVisual = %SlimeVisual

func _ready() -> void:
    enemy.attack_started.connect(_on_attack_started)

func _on_attack_started(_target: Node3D):
    slime_visual.play_attack_animation()