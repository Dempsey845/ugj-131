class_name MainMenu
extends Control

signal sign_up_requested
signal settings_requested

@export var sign_up_scene: PackedScene
@export var settings_scene: PackedScene

@onready var sign_up_button: Button = %SignUpButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	sign_up_button.pressed.connect(_on_sign_up_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	sign_up_button.grab_focus()


func _on_sign_up_pressed() -> void:
	if sign_up_scene:
		get_tree().change_scene_to_packed(sign_up_scene)
	else:
		sign_up_requested.emit()


func _on_settings_pressed() -> void:
	if settings_scene:
		get_tree().change_scene_to_packed(settings_scene)
	else:
		settings_requested.emit()


func _on_quit_pressed() -> void:
	get_tree().quit()

