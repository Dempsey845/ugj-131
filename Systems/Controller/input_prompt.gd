class_name InputPrompt
extends Area3D

@export var input_action: ControllerManager.InputAction

@export_category("Following")
@export var follow_speed: float = 10.0

@onready var key_input_mesh: MeshInstance3D = $MeshInstance3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var input_actions: Dictionary[ControllerManager.InputAction, String] = {
	ControllerManager.InputAction.Interact: "pickup"
}

var material: StandardMaterial3D
var followed_parent: Node3D
var parent_offset: Vector3

var shown: bool = false
var is_pressing: bool = false

var _can_be_shown: bool = true

var can_be_shown: bool:
	get:
		return _can_be_shown
	set(value):
		_can_be_shown = value

		if not value and shown:
			shown = false
			animation_player.play_backwards("show")
		else:
			_force_detection()


func _ready() -> void:
	_setup_parent_following()

	material = key_input_mesh.mesh.material

	var connected_joypads: Array[int] = Input.get_connected_joypads()
	var start_controller_type: ControllerManager.ControllerType = (
		ControllerManager.ControllerType.UNKNOWN
	)

	if not connected_joypads.is_empty():
		start_controller_type = ControllerManager.get_controller_type(
			connected_joypads[0]
		)

		ControllerManager._set_using_controller(true, connected_joypads[0])

	var icon_texture: Texture = (
		ControllerManager.input_action_icons[input_action][start_controller_type]
	)
	material.albedo_texture = icon_texture

	ControllerManager.input_device_changed.connect(
		_on_input_device_change
	)

	animation_player.animation_finished.connect(
		func(_animation_name: StringName) -> void:
			is_pressing = false
	)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _setup_parent_following() -> void:
	followed_parent = get_parent() as Node3D

	if not is_instance_valid(followed_parent):
		return

	parent_offset = followed_parent.to_local(global_position)

	var starting_global_transform: Transform3D = global_transform
	top_level = true
	global_transform = starting_global_transform


func _process(delta: float) -> void:
	_follow_parent(delta)

	if shown:
		var action: String = input_actions[input_action]

		if (
			not is_pressing
			and Input.is_action_just_pressed(action)
		):
			animation_player.play("press")
			is_pressing = true


func _follow_parent(delta: float) -> void:
	if not is_instance_valid(followed_parent):
		return

	var target_position: Vector3 = followed_parent.to_global(parent_offset)

	var follow_weight: float = 1.0 - exp(-follow_speed * delta)

	global_position = global_position.lerp(
		target_position,
		follow_weight
	)


func _on_input_device_change(
	_using_controller: bool,
	controller_type: ControllerManager.ControllerType
) -> void:
	var icon_texture: Texture = (
		ControllerManager.input_action_icons[input_action][controller_type]
	)
	material.albedo_texture = icon_texture


func _force_detection():
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		_on_body_entered(body)

func _on_body_entered(body: Node3D) -> void:
	if body is not Player:
		return

	if not shown and can_be_shown:
		animation_player.play("show")
		shown = true


func _on_body_exited(body: Node3D) -> void:
	if body is not Player:
		return

	if shown and can_be_shown:
		animation_player.play_backwards("show")
		shown = false