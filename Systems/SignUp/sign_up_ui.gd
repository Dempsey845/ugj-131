class_name SignUpUI
extends Control

@onready var name_input: LineEdit = %NameInput
@onready var consent_check_box: CheckBox = %ConsentCheckBox
@onready var submit_button: Button = %SubmitButton
@onready var error_label: Label = %ErrorLabel


func _ready() -> void:
	name_input.text_changed.connect(_on_form_changed)
	consent_check_box.toggled.connect(_on_consent_toggled)
	submit_button.pressed.connect(_on_submit_pressed)
	_update_form()
	name_input.grab_focus()


func _on_form_changed(_new_text: String) -> void:
	_update_form()


func _on_consent_toggled(_enabled: bool) -> void:
	_update_form()


func _update_form() -> void:
	var cleaned_name: String = name_input.text.strip_edges()
	var name_is_long_enough: bool = cleaned_name.length() >= 2
	var name_is_taken: bool = false

	for npc_name: String in NPC_Manager.npc_names:
		if npc_name.to_lower() == cleaned_name.to_lower():
			name_is_taken = true
			break

	var name_is_valid: bool = name_is_long_enough and not name_is_taken

	submit_button.disabled = not (
		name_is_valid
		and consent_check_box.button_pressed
	)

	if cleaned_name.is_empty():
		error_label.text = ""
	elif not name_is_long_enough:
		error_label.text = (
			"Your contestant name must contain at least 2 characters."
		)
	elif name_is_taken:
		error_label.text = (
			"A contestant with that name is already signed up!"
		)
	else:
		error_label.text = ""


func _on_submit_pressed() -> void:
	var player_name: String = name_input.text.strip_edges()
	if player_name.length() < 2 or not consent_check_box.button_pressed:
		return

	SceneManager.sign_up(player_name)

