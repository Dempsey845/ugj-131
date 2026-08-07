extends Node3D

@export var body: CharacterBody3D
@export var maximum_move_speed: float = 7.0
@export var blend_smoothing: float = 10.0

@onready var animation_tree: AnimationTree = $AnimationTree

var playback: AnimationNodeStateMachinePlayback
var current_blend: float = 0.0

var current_y_state: String = ""


func _ready() -> void:
	playback = animation_tree.get(
		"parameters/MovementStateMachine/playback"
	)
	
	if body.has_signal("jumped"):
		body.jumped.connect(_on_body_jumped)
		
	if body.has_signal("landed"):
		body.landed.connect(_on_body_landed)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(body):
		return
		
	if current_y_state != "Fall" and not body.is_on_floor() and body.velocity.y < 0.0:
		playback.travel("Fall")
		current_y_state = "Fall"

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

func _on_body_jumped():
	playback.travel("Jump")
	current_y_state = "Jump"

func _on_body_landed():
	playback.travel("Land")
	current_y_state = "Land"
