class_name PlayerItemPickupArea
extends Area3D

@export var item_holder: Marker3D
@export var player: Player

@onready var pickup_delay_timer: Timer = $PickupDelayTimer

var current_item: Item

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pickup"):
		if current_item and current_item.carrier == player:
			var look_direction: Vector3 = -player.visuals.basis.z
			current_item.drop(look_direction)
		else:
			try_pickup_item()

func try_pickup_item():
	if !pickup_delay_timer.is_stopped():
		return

	var overlapping_areas: Array[Area3D] = get_overlapping_areas()
	for area: Area3D in overlapping_areas:
		if area.get_parent() is not Item:
			continue

		var item: Item = area.get_parent()

		if item.collect(player, item_holder):
			current_item = item
			current_item.dropped.connect(_on_current_item_dropped)

		break

	pickup_delay_timer.start()

func _on_current_item_dropped():
	current_item.dropped.disconnect(_on_current_item_dropped)
	current_item = null
