class_name SettingsMenu
extends Control

const SETTINGS_PATH: String = "user://settings.cfg"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]
const FPS_LIMITS: Array[int] = [0, 30, 60, 120, 144, 165, 240]
const RENDER_SCALES: Array[float] = [0.5, 0.67, 0.75, 1.0]

@export_file("*.tscn") var main_menu_scene: String = "res://Systems/MainMenu/main_menu.tscn"

@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var master_value: Label = %MasterValue
@onready var sfx_value: Label = %SFXValue
@onready var music_value: Label = %MusicValue

@onready var display_mode: OptionButton = %DisplayMode
@onready var resolution: OptionButton = %Resolution
@onready var vsync: CheckButton = %VSync
@onready var fps_limit: OptionButton = %FPSLimit
@onready var render_scale: OptionButton = %RenderScale

@onready var apply_button: Button = %ApplyButton
@onready var reset_button: Button = %ResetButton
@onready var back_button: Button = %BackButton

var config: ConfigFile = ConfigFile.new()
var is_loading: bool = false


func _ready() -> void:
	_populate_options()
	_connect_controls()
	_load_settings()
	back_button.grab_focus()


func _populate_options() -> void:
	display_mode.add_item("WINDOWED")
	display_mode.add_item("BORDERLESS")
	display_mode.add_item("FULLSCREEN")

	for r_size: Vector2i in RESOLUTIONS:
		resolution.add_item("%d x %d" % [r_size.x, r_size.y])

	for limit: int in FPS_LIMITS:
		fps_limit.add_item("UNLIMITED" if limit == 0 else "%d FPS" % limit)

	for r_scale: float in RENDER_SCALES:
		render_scale.add_item("%d%%" % roundi(r_scale * 100.0))


func _connect_controls() -> void:
	master_slider.value_changed.connect(_on_audio_changed.bind("Master", master_value))
	sfx_slider.value_changed.connect(_on_audio_changed.bind("SFX", sfx_value))
	music_slider.value_changed.connect(_on_audio_changed.bind("Music", music_value))
	apply_button.pressed.connect(_apply_and_save)
	reset_button.pressed.connect(_reset_to_defaults)
	back_button.pressed.connect(_go_back)


func _load_settings() -> void:
	is_loading = true
	config.load(SETTINGS_PATH)

	master_slider.value = config.get_value("audio", "master", 100.0)
	sfx_slider.value = config.get_value("audio", "sfx", 100.0)
	music_slider.value = config.get_value("audio", "music", 100.0)
	display_mode.select(config.get_value("graphics", "display_mode", 0))
	resolution.select(config.get_value("graphics", "resolution", 2))
	vsync.button_pressed = config.get_value("graphics", "vsync", true)
	fps_limit.select(config.get_value("graphics", "fps_limit", 0))
	render_scale.select(config.get_value("graphics", "render_scale", 3))

	_update_audio_labels()
	is_loading = false
	_apply_settings()


func _apply_and_save() -> void:
	_apply_settings()
	_save_settings()


func _apply_settings() -> void:
	_set_bus_volume("Master", master_slider.value)
	_set_bus_volume("SFX", sfx_slider.value)
	_set_bus_volume("Music", music_slider.value)

	match display_mode.selected:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	if display_mode.selected == 0:
		DisplayServer.window_set_size(RESOLUTIONS[resolution.selected])
		_center_window()

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync.button_pressed
		else DisplayServer.VSYNC_DISABLED
	)
	Engine.max_fps = FPS_LIMITS[fps_limit.selected]
	get_viewport().scaling_3d_scale = RENDER_SCALES[render_scale.selected]


func _save_settings() -> void:
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.set_value("graphics", "display_mode", display_mode.selected)
	config.set_value("graphics", "resolution", resolution.selected)
	config.set_value("graphics", "vsync", vsync.button_pressed)
	config.set_value("graphics", "fps_limit", fps_limit.selected)
	config.set_value("graphics", "render_scale", render_scale.selected)
	config.save(SETTINGS_PATH)


func _reset_to_defaults() -> void:
	master_slider.value = 100.0
	sfx_slider.value = 100.0
	music_slider.value = 100.0
	display_mode.select(0)
	resolution.select(2)
	vsync.button_pressed = true
	fps_limit.select(0)
	render_scale.select(3)
	_apply_and_save()


func _on_audio_changed(value: float, bus_name: String, value_label: Label) -> void:
	value_label.text = "%d%%" % roundi(value)
	if not is_loading:
		_set_bus_volume(bus_name, value)


func _set_bus_volume(bus_name: String, percent: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Audio bus '%s' does not exist." % bus_name)
		return

	AudioServer.set_bus_mute(bus_index, percent <= 0.0)
	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(maxf(percent / 100.0, 0.0001))
	)


func _update_audio_labels() -> void:
	master_value.text = "%d%%" % roundi(master_slider.value)
	sfx_value.text = "%d%%" % roundi(sfx_slider.value)
	music_value.text = "%d%%" % roundi(music_slider.value)


func _center_window() -> void:
	var screen: int = DisplayServer.window_get_current_screen()
	var screen_position: Vector2i = DisplayServer.screen_get_position(screen)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen)
	var window_size: Vector2i = DisplayServer.window_get_size()
	DisplayServer.window_set_position(
		screen_position + (screen_size - window_size) / 2
	)


func _go_back() -> void:
	_save_settings()
	if main_menu_scene.is_empty():
		queue_free()
	else:
		get_tree().change_scene_to_file(main_menu_scene)
