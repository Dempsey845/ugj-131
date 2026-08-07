extends Node3D

@export var body: CharacterBody3D
@export var maximum_move_speed: float = 7.0
@export var blend_smoothing: float = 10.0

@onready var animation_tree: AnimationTree = $AnimationTree

var playback: AnimationNodeStateMachinePlayback
var current_blend: float = 0.0


func _ready() -> void:
	playback = animation_tree.get(
		"parameters/MovementStateMachine/playback"
	)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(body):
		return

	var horizontal_velocity: Vector2 = Vector2(
		body.velocity.x,
		body.velocity.z
	)

	var target_blend: float = clampf(
		horizontal_velocity.length() / maximum_move_speed,
		0.0,
		1.0
	)

	current_blend = move_toward(
		current_blend,
		target_blend,
		blend_smoothing * delta
	)

	animation_tree.set(
		"parameters/MovementStateMachine/MoveBlend/blend_position",
		current_blend
	)