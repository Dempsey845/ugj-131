class_name ConfettiParticles
extends Node3D

signal explosion_started
signal explosion_finished

@export var auto_explode: bool = true
@export var free_on_finished: bool = false

@onready var particles: GPUParticles3D = %Particles

func _ready() -> void:
	particles.finished.connect(_on_particles_finished)

	if auto_explode:
		explode()


func explode() -> void:
	particles.restart()
	particles.emitting = true
	explosion_started.emit()


func _on_particles_finished() -> void:
	explosion_finished.emit()

	if free_on_finished:
		queue_free()
