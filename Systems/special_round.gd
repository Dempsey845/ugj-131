class_name SpecialRound
extends Node

signal round_started
signal round_ended

@export_category("Round")
@export var round_duration: int = 30
@export var custom_status_label: String = "Watch out!"
@export var end_round_on_countdown_complete: bool = true

@export_category("Announcement")
@export_multiline var announcement_text: String
@export var announcement_icon: Texture2D
@export var announcement_duration: float = 6.0

@export_category("References")
@export var countdown_ui: CountdownUI
@export var announcement_manager: AnnouncementManager

var is_round_active: bool = false
var is_round_starting: bool = false


func start_round() -> void:
	if is_round_active or is_round_starting:
		return

	is_round_starting = true

	if (
		is_instance_valid(announcement_manager)
		and not announcement_text.is_empty()
	):
		await announcement_manager.start_custom_announcement(
			announcement_text,
			announcement_icon,
			announcement_duration
		)

	if not is_round_starting:
		return

	is_round_starting = false
	is_round_active = true

	_on_round_started()

	if not is_round_active:
		return

	_connect_countdown()

	if is_instance_valid(countdown_ui):
		countdown_ui.start_countdown(round_duration, false, custom_status_label)

	round_started.emit()


func end_round() -> void:
	if not is_round_active and not is_round_starting:
		return

	is_round_starting = false
	is_round_active = false

	_disconnect_countdown()

	if is_instance_valid(countdown_ui):
		countdown_ui.stop_countdown()

	_on_round_ended()
	round_ended.emit()


func _connect_countdown() -> void:
	if not is_instance_valid(countdown_ui):
		return

	if not countdown_ui.countdown_finished.is_connected(
		_on_countdown_finished
	):
		countdown_ui.countdown_finished.connect(
			_on_countdown_finished
		)


func _disconnect_countdown() -> void:
	if not is_instance_valid(countdown_ui):
		return

	if countdown_ui.countdown_finished.is_connected(
		_on_countdown_finished
	):
		countdown_ui.countdown_finished.disconnect(
			_on_countdown_finished
		)


func _on_countdown_finished() -> void:
	if not is_round_active:
		return

	_on_round_timeout()
	if end_round_on_countdown_complete:
		end_round()


# Overrides

func _on_round_started() -> void:
	pass


func _on_round_ended() -> void:
	pass


func _on_round_timeout() -> void:
	pass