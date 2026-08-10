extends Node3D

@onready var ice_vapour_particles: GPUParticles3D = $IceVapourParticles

func _ready() -> void:
    visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
    ice_vapour_particles.emitting = visible