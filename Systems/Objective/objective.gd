class_name Objective
extends Node

signal objective_started(item_data: ItemData)
signal objective_ended

@export var item_spawn_points: Array[Marker3D]
@export var player_score: Score
@export var confetti_particles: ConfettiParticles

var current_item: Item
var current_item_data: ItemData

func start_objective(item_data: ItemData):
	var spawn_point: Marker3D = item_spawn_points.pick_random()
	
	current_item = item_data.item_scene.instantiate()
	spawn_point.add_child(current_item)

	current_item_data = item_data
	
	objective_started.emit(item_data)

func stop_objective():
	objective_ended.emit()

	if is_instance_valid(current_item):
		if current_item.carrier:
			var carrier_score: Score

			if current_item.carrier is NPC:
				carrier_score = current_item.carrier.get_node("Score")
			else:
				carrier_score = player_score

			confetti_particles.global_position = current_item.carrier.global_position
			confetti_particles.explode()
			
			carrier_score.add_points(current_item_data.points_reward)

		current_item.queue_free()
		
	current_item = null
