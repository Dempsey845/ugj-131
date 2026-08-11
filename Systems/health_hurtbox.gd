class_name HealthHurtbox
extends Area3D

@export var health: Health

func register_hit(damage: int):
    if health.dead:
        return false
    
    health.take_damage(damage)

    return true