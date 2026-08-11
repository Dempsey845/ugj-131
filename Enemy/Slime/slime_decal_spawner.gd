class_name SlimeDecalSpawner
extends Node3D


@export_category("Decal")
@export var spawn_point: Node3D
@export var random_rotation: bool = true
@export var decal_height_offset: float = 0.015

@export_category("Trail")
@export var trail_enabled: bool = false
@export var trail_spacing: float = 1.5


var slime_decal_scene: PackedScene = preload(
	"uid://bd746qhugluct"
)

var last_decal_position: Vector3
var has_placed_decal: bool = false

func _ready() -> void:
	start_trail()


func _physics_process(_delta: float) -> void:
	if not trail_enabled:
		return

	_try_place_trail_decal()


func start_trail() -> void:
	trail_enabled = true
	has_placed_decal = false


func stop_trail() -> void:
	trail_enabled = false
	has_placed_decal = false


func _try_place_trail_decal() -> void:
	if not is_instance_valid(spawn_point):
		return

	var current_position := spawn_point.global_position

	if has_placed_decal:
		var distance_moved := current_position.distance_to(
			last_decal_position
		)

		if distance_moved < trail_spacing:
			return

	var decal := spawn_decal()

	if decal != null:
		last_decal_position = current_position
		has_placed_decal = true


func spawn_decal() -> Node3D:
	if not is_instance_valid(spawn_point):
		push_warning(
			"SlimeDecalSpawner has no spawn point assigned."
		)
		return null

	return spawn_decal_at(
		spawn_point.global_position,
		spawn_point.global_basis.y.normalized()
	)


func spawn_decal_at(
	world_position: Vector3,
	surface_normal: Vector3 = Vector3.UP
) -> Node3D:
	if surface_normal.is_zero_approx():
		surface_normal = Vector3.UP
	else:
		surface_normal = surface_normal.normalized()

	var decal := slime_decal_scene.instantiate() as Node3D

	if decal == null:
		push_error(
			"The slime decal scene root must inherit Node3D."
		)
		return null

	get_tree().current_scene.add_child(decal)

	var alignment := Basis(
		Quaternion(Vector3.UP, surface_normal)
	)

	if random_rotation:
		alignment = alignment.rotated(
			surface_normal,
			randf_range(0.0, TAU)
		)

	decal.global_transform = Transform3D(
		alignment,
		world_position
			+ surface_normal * decal_height_offset
	)

	return decal


func reset_trail() -> void:
	trail_enabled = false
	has_placed_decal = false