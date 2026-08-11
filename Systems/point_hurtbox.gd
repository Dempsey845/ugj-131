class_name PointHurtbox
extends Area3D

signal hurtbox_hit(hitbox: PointHitbox)

@export var score: Score

func register_hit(point_loss: int, hitbox: PointHitbox):
    score.remove_points(point_loss)
    hurtbox_hit.emit(hitbox)