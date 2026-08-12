extends Node

enum ControllerType {
	UNKNOWN,
	XBOX,
	PLAYSTATION,
}

enum InputKey
{
    CTRL,
    E,
    PS_CIRCLE,
    PS_SQUARE,
    PS_CROSS,
    XBOX_A,
    XBOX_B,
    XBOX_X
}

enum InputAction {
    Interact,
}

var input_action_keys: Dictionary[InputAction, Dictionary] = {
    InputAction.Interact: {
        ControllerType.XBOX: InputKey.XBOX_X,
		ControllerType.PLAYSTATION: InputKey.PS_SQUARE,
		ControllerType.UNKNOWN: InputKey.E
    }
}

var input_action_icons: Dictionary[InputAction, Dictionary] = {
    InputAction.Interact: {
        ControllerType.XBOX: preload("uid://c0el86wnu4x15"), # xbox_x.png
		ControllerType.PLAYSTATION: preload("uid://cyb2h340q6bfn"), # ps_square.png
		ControllerType.UNKNOWN: preload("uid://cjmi623e7p850") # key_e.png
    }
}

signal input_device_changed(using_controller: bool, controller_type: ControllerType)

var using_controller: bool = false

func get_controller_type(device_id: int) -> ControllerType:
	var controller_name: String = Input.get_joy_name(device_id).to_lower()

	if (
		"xbox" in controller_name
		or "xinput" in controller_name
	):
		return ControllerType.XBOX

	if (
		"playstation" in controller_name
		or "dualshock" in controller_name
		or "dualsense" in controller_name
		or "ps4" in controller_name
		or "ps5" in controller_name
	):
		return ControllerType.PLAYSTATION

	return ControllerType.UNKNOWN

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_set_using_controller(true, event.device)

	elif event is InputEventJoypadMotion:
		# Ignore tiny stick drift.
		if absf(event.axis_value) > 0.2:
			_set_using_controller(true, event.device)

	elif event is InputEventKey or event is InputEventMouseButton:
		_set_using_controller(false, event.device)

	elif event is InputEventMouseMotion:
		# Ignore tiny accidental mouse movements.
		if event.relative.length() > 2.0:
			_set_using_controller(false, event.device)


func _set_using_controller(value: bool, device_id: int) -> void:
	if using_controller == value:
		return

	using_controller = value
	input_device_changed.emit(using_controller, get_controller_type(device_id))

	print(get_controller_type(device_id))