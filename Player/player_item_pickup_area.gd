class_name PlayerItemPickupArea
extends Area3D

signal item_picked_up
signal item_dropped(item: Item)

@export var item_holder: Marker3D
@export var player: Player

@onready var pickup_delay_timer: Timer = $PickupDelayTimer

var current_item: Item

func _ready() -> void:
	player.knocked_down.connect(_on_knocked_down)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pickup"):
		if does_player_have_item():
			var look_direction: Vector3 = -player.visuals.basis.z
			drop_item(look_direction)
		else:
			try_pickup_item()

func drop_item(direction: Vector3):
	if current_item == null or !is_instance_valid(current_item):
		current_item = null
		return

	var item: Item = current_item
	current_item.drop(direction)
	item_dropped.emit(item)


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
			item_picked_up.emit()

		break

	pickup_delay_timer.start()

func _on_knocked_down():
	drop_item(player.knockback_direction)

func _on_current_item_dropped():
	current_item.dropped.disconnect(_on_current_item_dropped)
	current_item = null

func does_player_have_item():
	return is_instance_valid(current_item) and current_item.carrier == player
