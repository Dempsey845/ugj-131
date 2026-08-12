class_name Item
extends RigidBody3D

signal picked_up(carrier: Node3D)
signal dropped
signal became_available

enum State {
	AVAILABLE,
	CARRIED,
	DROPPED
}


@export var pickup_delay_after_drop: float = 1.0
@export var throw_force: float = 5.0
@export var upward_throw_force: float = 3.0
@export var force_character_to_pickup_on_collide: bool
@export var can_only_be_thrown_if_character_in_front: bool

@onready var pickup_area: Area3D = $PickupArea
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var state: State = State.AVAILABLE
var carrier: Node3D
var last_carrier: Node3D
var can_be_collected: bool = true

func _ready() -> void:
	freeze = false
	pickup_area.monitoring = true

	pickup_area.area_entered.connect(_on_pickup_area_entered)


func collect(new_carrier: Node3D, item_holder: Node3D ) -> bool:
	if not can_be_collected:
		return false

	if state == State.CARRIED:
		return false

	if not is_instance_valid(new_carrier):
		return false

	carrier = new_carrier
	state = State.CARRIED
	can_be_collected = false

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	freeze = true
	collision_shape.set_deferred("disabled", true)
	pickup_area.set_deferred("monitoring", false)

	reparent(item_holder)
	transform = Transform3D.IDENTITY

	picked_up.emit(carrier)
	return true


func drop(direction: Vector3) -> void:
	if state != State.CARRIED:
		return

	var old_transform: Transform3D = global_transform
	var level: Node = get_tree().current_scene

	reparent(level)
	global_transform = old_transform

	last_carrier = carrier
	carrier = null
	state = State.DROPPED

	freeze = false
	collision_shape.set_deferred("disabled", false)

	linear_velocity = (
		direction.normalized() * throw_force +
		Vector3.UP * upward_throw_force
	)

	angular_velocity = Vector3(
		randf_range(-8.0, 8.0),
		randf_range(-8.0, 8.0),
		randf_range(-8.0, 8.0)
	)

	dropped.emit()

	await get_tree().create_timer(
		pickup_delay_after_drop
	).timeout

	if state != State.DROPPED:
		return

	state = State.AVAILABLE
	can_be_collected = true
	pickup_area.set_deferred("monitoring", true)
	became_available.emit()

func _on_pickup_area_entered(area: Area3D):
	if !force_character_to_pickup_on_collide:
		return

	var body: Node3D = area.get_parent()

	if body is NPC:
		var npc: NPC = body
		npc.collect_item.call_deferred(self)
	elif body is Player:
		var player_item_pickup_area: PlayerItemPickupArea = body.get_node("PlayerItemPickupArea")

		player_item_pickup_area.pickup_item.call_deferred(self)

func is_item_hot_potato():
	return force_character_to_pickup_on_collide and can_only_be_thrown_if_character_in_front