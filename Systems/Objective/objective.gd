class_name Objective
extends Node

signal objective_started(item_data: ItemData)
signal objective_ended

@export var item_spawn_points: Array[Marker3D]

func start_objective(item_data: ItemData):
	var spawn_point: Marker3D = item_spawn_points.pick_random()
	
	var item: Item = item_data.item_scene.instantiate()
	spawn_point.add_child(item)
	
	objective_started.emit(item_data)

func stop_objective():
	objective_ended.emit()