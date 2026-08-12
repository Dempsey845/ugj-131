class_name Character
extends Node3D

@export var body: CharacterBody3D
@export var item_manager: Node3D

@export var left_shoe: Node3D
@export var right_shoe: Node3D

@export var maximum_move_speed: float = 7.0
@export var blend_smoothing: float = 10.0

@export var random_base_colour: bool = true
@export var random_shoe_colour: bool = true
@export var character_mesh: MeshInstance3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var goofy_goggles: Node3D = %GoofyGoggles
@onready var confused_particles: ConfusedParticles = $ConfusedParticles
@onready var jump_player: AudioStreamPlayer3D = $JumpPlayer
@onready var slide_player: AudioStreamPlayer3D = $SlidePlayer
@onready var slide_hit_player: AudioStreamPlayer3D = $SlideHitPlayer

var playback: AnimationNodeStateMachinePlayback
var current_blend: float = 0.0

var current_hold_blend: float
var target_hold_blend: float

var current_state: String = ""

var has_land_signal: bool
var has_just_landed: bool

var animation_prefix = "Armature|"

var slide_animation_active: bool = false

var color: Color
var shoe_color: Color

func _ready() -> void:
	playback = animation_tree.get(
		"parameters/MovementStateMachine/playback"
	)
	
	if body.has_signal("jumped"):
		body.jumped.connect(_on_body_jumped)
		
	if body.has_signal("landed"):
		body.landed.connect(_on_body_landed)
		has_land_signal = true

	if item_manager.has_signal("item_picked_up"):
		item_manager.item_picked_up.connect(_on_item_picked_up)

	if item_manager.has_signal("item_dropped"):
		item_manager.item_dropped.connect(_on_item_dropped)

	animation_tree.animation_finished.connect(func(anim_name: String):
		if anim_name == animation_prefix + "Land":
			current_state = "MoveBlend"
	)

	body.slide_started.connect(_on_body_slide_started)
	body.slide_ended.connect(_on_body_slide_ended)
	body.knocked_down.connect(_on_body_knocked_down)

	var base_colour: Color = Color("fd7352")
	color = base_colour

	if random_base_colour:
		base_colour = Color.from_hsv(
			randf(),
			randf_range(0.55, 0.8),
			randf_range(0.8, 1.0)
		)

		var base_material := (
			character_mesh
			.get_surface_override_material(0)
			.duplicate()
		) as StandardMaterial3D

		base_material.albedo_color = base_colour
		color = base_colour

		character_mesh.set_surface_override_material(
			0,
			base_material
		)

	if random_shoe_colour:
		var hue_offset: float = randf_range(
			0.3,
			0.7
		)

		var shoe_hue: float = fmod(
			base_colour.h + hue_offset,
			1.0
		)

		var shoe_colour := Color.from_hsv(
			shoe_hue,
			randf_range(0.6, 0.85),
			randf_range(0.8, 1.0)
		)

		shoe_color = shoe_colour

		var shoe_material := (
			character_mesh
			.get_surface_override_material(2)
			.duplicate()
		) as StandardMaterial3D

		shoe_material.albedo_color = shoe_colour

		character_mesh.set_surface_override_material(
			2,
			shoe_material
		)
	else:
		shoe_color = Color.BLACK


func _physics_process(delta: float) -> void:
	if not is_instance_valid(body):
		return

	var body_is_sliding: bool = body.get(
		"is_sliding"
	)

	if (
		slide_animation_active
		and not body_is_sliding
	):
		_on_body_slide_ended()

	if (
		not slide_animation_active
		and current_state != "Fall"
		and not body.is_on_floor()
		and body.velocity.y < 0.0
	):
		playback.travel("Fall")
		current_state = "Fall"
		has_just_landed = false

	if (
		not slide_animation_active
		and not has_just_landed
		and not has_land_signal
		and current_state == "Fall"
		and body.is_on_floor()
	):
		playback.travel("Land")
		current_state = "Land"
		has_just_landed = true

	var horizontal_velocity: Vector2 = Vector2(
		body.velocity.x,
		body.velocity.z
	)

	var target_blend: float = clampf(
		horizontal_velocity.length()
			/ maximum_move_speed,
		0.0,
		1.0
	)

	current_blend = move_toward(
		current_blend,
		target_blend,
		blend_smoothing * delta
	)

	current_hold_blend = move_toward(
		current_hold_blend,
		target_hold_blend,
		5.0 * delta
	)

	animation_tree.set(
		"parameters/MovementStateMachine/MoveBlend/blend_position",
		current_blend
	)

	animation_tree.set(
		"parameters/HoldBlend/blend_amount",
		current_hold_blend
	)

func _on_body_jumped() -> void:
	if slide_animation_active:
		return

	jump_player.play()

	playback.travel("Jump")
	current_state = "Jump"


func _on_body_landed() -> void:
	if slide_animation_active:
		return

	playback.travel("Land")
	current_state = "Land"

func _on_body_slide_started() -> void:
	slide_animation_active = true
	current_state = "Slide"

	slide_player.play()

	playback.start(
		"Slide",
		true
	)


func _on_body_slide_ended() -> void:
	if not slide_animation_active:
		return

	slide_animation_active = false

	if (
		not body.is_on_floor()
		and body.velocity.y < 0.0
	):
		current_state = "Fall"

		playback.start(
			"Fall",
			true
		)
	else:
		current_state = "MoveBlend"

		playback.start(
			"MoveBlend",
			true
		)

func _on_item_picked_up():
	target_hold_blend = 1.0

	var item: Item = item_manager.get_current_item()

	if !item.is_connected("tree_exited", _on_item_tree_exited):
		item.tree_exited.connect(_on_item_tree_exited)

func _on_item_tree_exited():
	target_hold_blend = 0.0

func _on_item_dropped(item):
	target_hold_blend = 0.0
	item.tree_exited.disconnect(_on_item_tree_exited)

func show_goggles():
	goofy_goggles.visible = true
	confused_particles.set_particle_emission(true)

func hide_goggles():
	goofy_goggles.visible = false
	confused_particles.set_particle_emission(false)

func show_shoes():
	left_shoe.visible = true
	right_shoe.visible = true

func hide_shoes():
	left_shoe.visible = false
	right_shoe.visible = false

func _on_body_knocked_down():
	slide_hit_player.play()
