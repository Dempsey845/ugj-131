class_name CountdownUI
extends Control

@export var objective: Objective
@export var game_manager: GameManager

@onready var timer_card: PanelContainer = %TimerCard
@onready var countdown_label: Label = %CountdownLabel
@onready var time_progress: ProgressBar = %TimeProgress
@onready var status_label: Label = %StatusLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const NORMAL_COLOUR: Color = Color(0.984, 0.745, 0.18)
const URGENT_COLOUR: Color = Color(1.0, 0.32, 0.28)

var time: float = 0.0
var countdown_active: bool = false


func _ready() -> void:
	timer_card.visible = false

	if is_instance_valid(objective):
		objective.objective_started.connect(_on_objective_started)
	else:
		push_warning("CountdownUI requires an Objective reference.")


func _process(delta: float) -> void:
	if not countdown_active:
		return

	time = maxf(time - delta, 0.0)
	game_manager.round_time = time
	time_progress.value = time
	_update_display()

	if time <= 0.0:
		_finish_countdown()


func start_countdown(from: int) -> void:
	animation_player.play("show")
	time = maxf(float(from), 0.0)
	countdown_active = time > 0.0
	time_progress.max_value = maxf(time, 1.0)
	time_progress.value = time
	timer_card.visible = countdown_active
	_update_display()


func _update_display() -> void:
	var displayed_seconds: int = ceili(time)
	countdown_label.text = str(displayed_seconds)

	var is_urgent: bool = displayed_seconds <= game_manager.current_item_data.urgent_time
	var colour: Color = URGENT_COLOUR if is_urgent else NORMAL_COLOUR
	countdown_label.add_theme_color_override("font_color", colour)
	time_progress.modulate = colour
	status_label.text = "HURRY UP!" if is_urgent else "ITEM HUNT ACTIVE"
	status_label.add_theme_color_override("font_color", colour)


func _finish_countdown() -> void:
	countdown_active = false
	countdown_label.text = "0"
	timer_card.visible = false

	if is_instance_valid(objective):
		objective.stop_objective()
	
	animation_player.play_backwards("show")


func _on_objective_started(item_data: ItemData) -> void:
	start_countdown(item_data.seconds_to_collect)
