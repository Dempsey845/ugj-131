class_name VictoryCharacter
extends Node3D

@export var character_mesh: MeshInstance3D

@onready var name_label: Label3D = $NameLabel

func set_character_name(character_name: String):
	name_label.text = character_name

func set_color(base_color: Color, shoe_color: Color):
	var base_material: StandardMaterial3D = (
			character_mesh
			.get_surface_override_material(0)
			.duplicate()
		) as StandardMaterial3D
	
	base_material.albedo_color = base_color

	var shoe_material: StandardMaterial3D = (
		character_mesh
		.get_surface_override_material(2)
		.duplicate()
	) as StandardMaterial3D

	shoe_material.albedo_color = shoe_color

	character_mesh.set_surface_override_material(
		0,
		base_material
	)

	character_mesh.set_surface_override_material(
		2,
		shoe_material
	)
