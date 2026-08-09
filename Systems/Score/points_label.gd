extends Label3D

@export var score: Score

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if score == null:
		score = get_tree().current_scene.get_node("PlayerScore")

	score.points_added.connect(_on_points_added)
	score.points_changed.connect(_on_points_changed)

func _on_points_added(_amount_added, _current_points):
	animation_player.play("points_gained")

func _on_points_changed(points: int):
	text = str(points)
