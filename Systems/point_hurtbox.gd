class_name PointHurtbox
extends Area3D

@export var score: Score

func register_hit(point_loss: int):
    score.current_points -= point_loss