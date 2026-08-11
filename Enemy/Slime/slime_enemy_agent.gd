extends Node

@export var health: Health
@export var death_particles_marker: Marker3D

@onready var enemy: Enemy = get_parent()
@onready var slime_visual: SlimeVisual = %SlimeVisual

var slime_death_particles_scene: PackedScene = preload("uid://j4qtrihkj32")

func _ready() -> void:
	enemy.attack_started.connect(_on_attack_started)
	enemy.death_started.connect(_on_death_started)
	health.damage_taken.connect(_on_damage_taken)

func _on_attack_started(_target: Node3D):
	slime_visual.play_attack_animation()

func _on_death_started():
	slime_visual.play_death_animation()
	
	var death_particles =  slime_death_particles_scene.instantiate()
	get_tree().current_scene.add_child(death_particles)
	death_particles.global_position = death_particles_marker.global_position

func _on_damage_taken():
	slime_visual.play_hit_animation()
