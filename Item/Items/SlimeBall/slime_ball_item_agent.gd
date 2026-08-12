extends ItemAgent


@export_category("Slime Trail")
@export var particles: GPUParticles3D
@export var trail_spacing: float = 1.5
@export var random_rotation: bool = true
@export var decal_height_offset: float = 0.015
@export var minimum_bounce_interval: float = 0.1

@onready var ground_raycast: RayCast3D = %GroundRaycast
@onready var slime_bounce_player: AudioStreamPlayer3D = %SlimeBouncePlayer


var slime_trail_decal_scene: PackedScene = preload(
	"uid://bd746qhugluct"
)

var trail_enabled: bool = false
var last_decal_position: Vector3
var has_placed_decal: bool = false

var can_play_bounce_sound: bool = true


func _ready() -> void:
	get_parent().body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if not trail_enabled:
		return

	_try_place_slime_decal()


func _on_item_picked_up(carrier) -> void:
	trail_enabled = true
	has_placed_decal = false

	particles.restart()
	particles.emitting = true

	super._on_item_picked_up(carrier)


func _on_item_dropped() -> void:
	trail_enabled = false
	has_placed_decal = false
	particles.emitting = false

	super._on_item_dropped()


func _try_place_slime_decal() -> void:
	ground_raycast.force_raycast_update()

	if not ground_raycast.is_colliding():
		return

	var ground_position: Vector3 = ground_raycast.get_collision_point()
	var ground_normal: Vector3 = ground_raycast.get_collision_normal()

	if has_placed_decal:
		var flat_offset: Vector2 = Vector2(
			ground_position.x - last_decal_position.x,
			ground_position.z - last_decal_position.z
		)

		if flat_offset.length() < trail_spacing:
			return

	_place_slime_decal(ground_position, ground_normal)

	last_decal_position = ground_position
	has_placed_decal = true


func _place_slime_decal(
	ground_position: Vector3,
	ground_normal: Vector3
) -> void:
	var decal: Node3D = slime_trail_decal_scene.instantiate()

	get_tree().current_scene.add_child(decal)

	var alignment: Basis = Basis(
		Quaternion(Vector3.UP, ground_normal)
	)

	if random_rotation:
		alignment = alignment.rotated(
			ground_normal,
			randf_range(0.0, TAU)
		)

	decal.global_transform = Transform3D(
		alignment,
		ground_position + ground_normal * decal_height_offset
	)


func reset_effect() -> void:
	trail_enabled = false
	has_placed_decal = false
	particles.emitting = false

	super.reset_effect()

func _on_body_entered(body: Node3D) -> void:
	if not can_play_bounce_sound:
		return

	print(body.name)

	can_play_bounce_sound = false

	slime_bounce_player.play()

	await get_tree().create_timer(minimum_bounce_interval).timeout
	can_play_bounce_sound = true