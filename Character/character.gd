extends Node3D

@export var body: CharacterBody3D
@export var maximum_move_speed: float = 7.0
@export var blend_smoothing: float = 10.0

@onready var animation_tree: AnimationTree = $AnimationTree

var playback: AnimationNodeStateMachinePlayback
var current_blend: float = 0.0

var current_state: String = ""

var has_land_signal: bool
var has_just_landed: bool

var animation_prefix = "Armature|"

func _ready() -> void:
	playback = animation_tree.get(
		"parameters/MovementStateMachine/playback"
	)
	
	if body.has_signal("jumped"):
		body.jumped.connect(_on_body_jumped)
		
	if body.has_signal("landed"):
		body.landed.connect(_on_body_landed)
		has_land_signal = true

	animation_tree.animation_finished.connect(func(anim_name: String):
		if anim_name == animation_prefix + "Land":
			current_state = "MoveBlend"
	)

	body.slide_started.connect(_on_body_slide_started)
	body.slide_ended.connect(_on_body_slide_ended)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(body):
		return
		
	if current_state != "Fall" and not body.is_on_floor() and body.velocity.y < 0.0:
		playback.travel("Fall")
		current_state = "Fall"
		has_just_landed = false
		
	if !has_just_landed and !has_land_signal and current_state == "Fall":
		if body.is_on_floor():
			playback.travel("Land")
			current_state = "Land"
			has_just_landed = true

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
	current_state = "Jump"

func _on_body_landed():
	playback.travel("Land")
	current_state = "Land"

func _on_body_slide_started():
	playback.travel("Slide")

func _on_body_slide_ended():
	playback.travel("MoveBlend")