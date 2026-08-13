class_name PauseMenu
extends CanvasLayer

@export_file("*.tscn") var main_menu_scene: String = \
	"res://Systems/MainMenu/main_menu.tscn"

@onready var overlay: Control = $Overlay
@onready var return_to_menu_button: Button = \
	%ReturnToMenuButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	return_to_menu_button.pressed.connect(
		_on_return_to_menu_pressed
	)
	quit_button.pressed.connect(_on_quit_pressed)

	hide_pause_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()

		if overlay.visible:
			hide_pause_menu()
		else:
			show_pause_menu()


func show_pause_menu() -> void:
	get_tree().paused = true
	overlay.show()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return_to_menu_button.grab_focus()


func hide_pause_menu() -> void:
	overlay.hide()
	get_tree().paused = false

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_return_to_menu_pressed() -> void:
	get_tree().paused = false

	if main_menu_scene.is_empty():
		push_error("PauseMenu: Main menu scene path is empty.")
		return

	TransitionUi.change_scene(main_menu_scene)


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()