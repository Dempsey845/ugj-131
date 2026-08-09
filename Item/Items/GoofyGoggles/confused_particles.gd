class_name ConfusedParticles
extends Node3D

@onready var question_marks: GPUParticles3D = $QuestionMarks
@onready var stars: GPUParticles3D = $Stars
@onready var rings: GPUParticles3D = $Rings

func set_particle_emission(emitting: bool):
    question_marks.emitting = emitting
    stars.emitting = emitting
    rings.emitting = emitting