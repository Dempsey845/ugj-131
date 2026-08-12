extends Node3D

@export_category("Pillar Heights")
@export var gold_height: float = 25.0
@export var silver_height: float = 20.0
@export var bronze_height: float = 15.0

@export_category("Animation")
@export var tween_duration: float = 6.5
@export var delay_between_pillars: float = 0.15
@export var pillar_start_delay: float = 0.75

@export_category("Camera Intro")
@export var camera_intro_delay: float = 2.0
@export var camera_intro_duration: float = 3.0

@export_category("Camera Follow")
@export var camera_offset: Vector3 = Vector3(0.0, 3.0, 9.0)
@export var camera_follow_speed: float = 2.5
@export var camera_look_at_gold: bool = true

@onready var victory_character_gold: Node3D = $VictoryCharacter_Gold
@onready var victory_character_silver: Node3D = $VictoryCharacter_Silver
@onready var victory_character_bronze: Node3D = $VictoryCharacter_Bronze

@onready var gold_pillar: Node3D = $GoldPillar
@onready var silver_pillar: Node3D = $SilverPillar
@onready var bronze_pillar: Node3D = $BronzePillar

@onready var gold_character_point: Marker3D = (
	$GoldPillar/CharacterPoint
)
@onready var silver_character_point: Marker3D = (
	$SilverPillar/CharacterPoint
)
@onready var bronze_character_point: Marker3D = (
	$BronzePillar/CharacterPoint
)

@onready var confetti_particles: ConfettiParticles = (
	$ConfettiParticles
)
@onready var camera: Camera3D = $Camera3D

var camera_follow_enabled: bool = false

var camera_intro_start: Transform3D
var camera_intro_target: Transform3D


func _ready() -> void:
	gold_pillar.scale.y = 0.0
	silver_pillar.scale.y = 0.0
	bronze_pillar.scale.y = 0.0

	_update_character_positions()

	await get_tree().process_frame

	if camera_intro_delay > 0.0:
		await get_tree().create_timer(camera_intro_delay).timeout

	await _move_camera_into_start_position()

	if pillar_start_delay > 0.0:
		await get_tree().create_timer(pillar_start_delay).timeout

	camera_follow_enabled = true
	_start_pillar_animation()


func _process(delta: float) -> void:
	_update_character_positions()

	if camera_follow_enabled:
		_update_camera(delta)


func _update_character_positions() -> void:
	victory_character_gold.global_position = (
		gold_character_point.global_position
	)
	victory_character_silver.global_position = (
		silver_character_point.global_position
	)
	victory_character_bronze.global_position = (
		bronze_character_point.global_position
	)


func _move_camera_into_start_position() -> void:
	camera_intro_start = camera.global_transform

	var target_position := (
		gold_character_point.global_position
		+ camera_offset
	)

	camera_intro_target = camera.global_transform
	camera_intro_target.origin = target_position

	if camera_look_at_gold:
		camera_intro_target = camera_intro_target.looking_at(
			gold_character_point.global_position,
			Vector3.UP
		)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		_set_camera_intro_progress,
		0.0,
		1.0,
		camera_intro_duration
	)

	await tween.finished


func _set_camera_intro_progress(progress: float) -> void:
	camera.global_transform = camera_intro_start.interpolate_with(
		camera_intro_target,
		progress
	)


func _start_pillar_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		bronze_pillar,
		"scale:y",
		bronze_height,
		tween_duration
	)

	tween.tween_property(
		silver_pillar,
		"scale:y",
		silver_height,
		tween_duration
	).set_delay(delay_between_pillars)

	tween.tween_property(
		gold_pillar,
		"scale:y",
		gold_height,
		tween_duration
	).set_delay(delay_between_pillars * 2.0)

	tween.chain().tween_callback(func():
		confetti_particles.explode()
		await get_tree().create_timer(2.0).timeout
		TransitionUi.change_scene("res://Systems/SignUp/sign_up_ui.tscn", "Thanks for playing!")
	)


func _update_camera(delta: float) -> void:
	var target_position := (
		gold_character_point.global_position
		+ camera_offset
	)

	var follow_weight := (
		1.0 - exp(-camera_follow_speed * delta)
	)

	camera.global_position = camera.global_position.lerp(
		target_position,
		follow_weight
	)

	if camera_look_at_gold:
		camera.look_at(
			gold_character_point.global_position,
			Vector3.UP
		)
