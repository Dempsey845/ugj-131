class_name ShoeBox
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ice_vapour_particles: GPUParticles3D = $IceVapourParticles

func open_lid():
    animation_player.play_backwards("close_lid")
    ice_vapour_particles.emitting = true

func close_lid():
    animation_player.play("close_lid")
    ice_vapour_particles.emitting = false