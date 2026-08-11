class_name SlimeVisual
extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var enemy_point_hitbox: PointHitbox = $EnemyPointHitbox

func _ready() -> void:
    disable_hitbox()

func play_attack_animation():
    animation_tree.set("parameters/AttackShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func play_hit_animation():
    animation_tree.set("parameters/HitShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func play_death_animation():
    animation_tree.set("parameters/DeathShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func enable_hitbox():
    enemy_point_hitbox.enable_hitbox()

func disable_hitbox():
    enemy_point_hitbox.disable_hitbox()