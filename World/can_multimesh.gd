class_name ShelfMultiMesh
extends MultiMeshInstance3D

@export_category("Shelf Layout")
@export_range(1, 20, 1) var rows: int = 3
@export_range(1, 100, 1) var columns: int = 8

@export var column_spacing: float = 0.35
@export var row_spacing: float = 0.5
@export var starting_offset: Vector3 = Vector3.ZERO
@export var center_horizontally: bool = true
@export var populate_on_ready: bool = true

@export_category("Random Variation")
@export var random_seed: int = 1
@export var random_position: Vector3 = Vector3(
	0.015,
	0.0,
	0.015
)

@export_range(0.0, 45.0) var random_y_rotation: float = 4.0
@export_range(0.0, 0.5) var random_scale: float = 0.03


func _ready() -> void:
	if populate_on_ready:
		populate_shelf()


func populate_shelf() -> void:
	if multimesh == null:
		push_warning(
			"ShelfMultiMesh requires a MultiMesh resource."
		)
		return

	if multimesh.mesh == null:
		push_warning(
			"Assign an item mesh to the MultiMesh resource."
		)
		return

	var instance_total: int = rows * columns

	multimesh.instance_count = instance_total
	multimesh.visible_instance_count = instance_total

	var random := RandomNumberGenerator.new()
	random.seed = random_seed

	var index: int = 0

	for row: int in rows:
		for column: int in columns:
			var item_position: Vector3 = _get_item_position(
				row,
				column
			)

			item_position += Vector3(
				random.randf_range(
					-random_position.x,
					random_position.x
				),
				random.randf_range(
					-random_position.y,
					random_position.y
				),
				random.randf_range(
					-random_position.z,
					random_position.z
				)
			)

			var item_rotation: float = random.randf_range(
				-random_y_rotation,
				random_y_rotation
			)

			var item_scale: float = 1.0 + random.randf_range(
				-random_scale,
				random_scale
			)

			var item_basis: Basis = Basis.IDENTITY

			item_basis = item_basis.rotated(
				Vector3.UP,
				deg_to_rad(item_rotation)
			)

			item_basis = item_basis.scaled(
				Vector3.ONE * item_scale
			)

			multimesh.set_instance_transform(
				index,
				Transform3D(
					item_basis,
					item_position
				)
			)

			index += 1


func _get_item_position(
	row: int,
	column: int
) -> Vector3:
	var horizontal_offset: float = 0.0

	if center_horizontally:
		horizontal_offset = (
			float(columns - 1)
			* column_spacing
			* 0.5
		)

	return starting_offset + Vector3(
		column * column_spacing - horizontal_offset,
		0.0,
		row * row_spacing
	)