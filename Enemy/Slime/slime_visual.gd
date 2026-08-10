class_name SlimeVisual
extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree

func play_attack_animation():
    animation_tree.set("parameters/AttackShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func play_hit_animation():
    animation_tree.set("parameters/HitShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func play_death_animation():
    animation_tree.set("parameters/DeathShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)