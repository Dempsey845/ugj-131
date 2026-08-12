class_name LeaderboardCard
extends PanelContainer

const RANK_COLOURS: Array[Color] = [
	Color(0.984, 0.745, 0.18),
	Color(0.72, 0.76, 0.83),
	Color(0.78, 0.45, 0.22),
]

@onready var rank_panel: PanelContainer = %RankPanel
@onready var rank_label: Label = %RankLabel
@onready var name_label: Label = %NameLabel
@onready var seconds_label: Label = %SecondsLabel
@onready var character_icon: CharacterIcon = %CharacterIcon

var player_id: StringName
var current_rank: int = -1
var _tween: Tween
var _is_hiding: bool = false

func set_player_data(
	id: StringName,
	display_name: String,
	seconds: float,
	color: Color
) -> void:
	player_id = id
	name_label.text = display_name
	seconds_label.text = "%.1f s" % seconds
	character_icon.set_head_color(color)


func move_to_rank(rank: int, target_position: Vector2, duration: float) -> void:
	_kill_tween()
	_is_hiding = false

	var entering: bool = not visible
	current_rank = rank
	rank_label.text = str(rank + 1)
	rank_panel.modulate = RANK_COLOURS[clampi(rank, 0, 2)]

	if entering:
		position = target_position + Vector2(-28.0, 0.0)
		modulate.a = 0.0
		visible = true

	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target_position, duration)
	_tween.tween_property(self, "modulate:a", 1.0, duration * 0.7)


func hide_card(duration: float) -> void:
	if not visible or _is_hiding:
		return

	_kill_tween()
	_is_hiding = true
	current_rank = -1
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "position:x", position.x - 24.0, duration)
	_tween.tween_property(self, "modulate:a", 0.0, duration * 0.7)
	_tween.chain().tween_callback(_finish_hiding)


func _finish_hiding() -> void:
	visible = false
	_is_hiding = false


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
