extends Control

signal transition_covered
signal transition_finished

@export_category("Animation")
@export var cover_duration: float = 1.2
@export var covered_delay: float = 1.5
@export var uncover_duration: float = 1.2

@export_category("Text")
@export var default_message: String = "Loading..."

@onready var transition_rect: ColorRect = $TransitionRect
@onready var message_container: Control = $MessageContainer
@onready var message_label: Label = $MessageContainer/MessageLabel

var is_transitioning: bool = false
var transition_material: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	transition_material = transition_rect.material as ShaderMaterial
	transition_material.set_shader_parameter("progress", 0.0)

	message_container.modulate.a = 0.0
	message_container.scale = Vector2(0.6, 0.6)
	message_container.pivot_offset = message_container.size * 0.5

	hide()


## Covers and uncovers the screen without changing scene.
func play_transition(message: String = "") -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_prepare_transition(message)

	await _cover_screen()

	transition_covered.emit()

	if covered_delay > 0.0:
		await get_tree().create_timer(
			covered_delay,
			true,
			false,
			true
		).timeout

	await _uncover_screen()

	is_transitioning = false
	transition_finished.emit()


## Covers the screen, changes scene, and then uncovers it.
func change_scene(
	scene_path: String,
	message: String = ""
) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_prepare_transition(message)

	await _cover_screen()

	transition_covered.emit()

	var change_error: Error = get_tree().change_scene_to_file(scene_path)

	if change_error != OK:
		push_error(
			"TransitionUI could not change scene to: %s" % scene_path
		)

		await _uncover_screen()
		is_transitioning = false
		transition_finished.emit()
		return

	# Give the new scene one frame to enter the tree.
	await get_tree().process_frame

	if covered_delay > 0.0:
		await get_tree().create_timer(
			covered_delay,
			true,
			false,
			true
		).timeout

	await _uncover_screen()

	is_transitioning = false
	transition_finished.emit()


## Covers the screen and leaves it covered.
func cover(message: String = "") -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_prepare_transition(message)

	await _cover_screen()

	is_transitioning = false
	transition_covered.emit()


## Uncovers a previously covered screen.
func uncover() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	show()

	await _uncover_screen()

	is_transitioning = false
	transition_finished.emit()


func set_message(message: String) -> void:
	message_label.text = message if not message.is_empty() else default_message


func _prepare_transition(message: String) -> void:
	show()
	move_to_front()
	mouse_filter = Control.MOUSE_FILTER_STOP

	set_message(message)

	transition_material.set_shader_parameter("progress", 0.0)
	message_container.modulate.a = 0.0
	message_container.scale = Vector2(0.6, 0.6)
	message_container.rotation = deg_to_rad(-6.0)


func _cover_screen() -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel()

	tween.tween_method(
		_set_shader_progress,
		0.0,
		1.0,
		cover_duration
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		message_container,
		"modulate:a",
		1.0,
		cover_duration * 0.45
	).set_delay(cover_duration * 0.35)

	tween.tween_property(
		message_container,
		"scale",
		Vector2.ONE,
		cover_duration * 0.55
	).set_delay(cover_duration * 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		message_container,
		"rotation",
		0.0,
		cover_duration * 0.5
	).set_delay(cover_duration * 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished


func _uncover_screen() -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel()

	tween.tween_method(
		_set_shader_progress,
		1.0,
		0.0,
		uncover_duration
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)

	tween.tween_property(
		message_container,
		"modulate:a",
		0.0,
		uncover_duration * 0.25
	)

	tween.tween_property(
		message_container,
		"scale",
		Vector2(1.35, 1.35),
		uncover_duration * 0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await tween.finished

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func _set_shader_progress(value: float) -> void:
	transition_material.set_shader_parameter("progress", value)
