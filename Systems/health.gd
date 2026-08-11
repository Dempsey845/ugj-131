class_name Health
extends Node

signal death
signal damage_taken

@export var max_health: int = 3

var _current_health: int = 0
var current_health: int:
    get():
        return _current_health
    set(value):
        _current_health = value

var dead: bool

func _ready() -> void:
    current_health = max_health

func take_damage(damage: int):
    if dead:
        return
    
    current_health -= damage

    if current_health <= 0:
        dead = true
        death.emit()
    else:
        damage_taken.emit()