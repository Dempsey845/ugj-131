extends Node3D

@export_category("Pillar Heights")
@export var gold_height: float = 25.0
@export var silver_height: float = 20.0
@export var bronze_height: float = 15.0

@export_category("Animation")
@export var tween_duration: float = 6.5
@export var delay_between_pillars: float = 0.15

@export_category("Camera")
@export var camera_offset: Vector3 = Vector3(0.0, 3.0, 9.0)
@export var camera_follow_speed: float = 4.0
@export var camera_look_at_gold: bool = true

@onready var victory_character_gold: Node3D = $VictoryCharacter_Gold
@onready var victory_character_silver: Node3D = $VictoryCharacter_Silver
@onready var victory_character_bronze: Node3D = $VictoryCharacter_Bronze

@onready var gold_pillar: Node3D = $GoldPillar
@onready var silver_pillar: Node3D = $SilverPillar
@onready var bronze_pillar: Node3D = $BronzePillar

@onready var gold_character_point: Marker3D = $GoldPillar/CharacterPoint
@onready var silver_character_point: Marker3D = $SilverPillar/CharacterPoint
@onready var bronze_character_point: Marker3D = $BronzePillar/CharacterPoint

@onready var confetti_particles: ConfettiParticles = $ConfettiParticles

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	gold_pillar.scale.y = 0.0
	silver_pillar.scale.y = 0.0
	bronze_pillar.scale.y = 0.0

	await get_tree().create_timer(2.0).timeout

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

	tween.finished.connect(confetti_particles.explode)


func _process(delta: float) -> void:
	victory_character_gold.global_position = gold_character_point.global_position
	victory_character_silver.global_position = silver_character_point.global_position
	victory_character_bronze.global_position = bronze_character_point.global_position

	_update_camera(delta)


func _update_camera(delta: float) -> void:
	var target_position := (
		gold_character_point.global_position
		+ camera_offset
	)

	# Frame-rate-independent smoothing.
	var follow_weight := 1.0 - exp(-camera_follow_speed * delta)

	camera.global_position = camera.global_position.lerp(
		target_position,
		follow_weight
	)

	if camera_look_at_gold:
		camera.look_at(
			gold_character_point.global_position,
			Vector3.UP
		)
