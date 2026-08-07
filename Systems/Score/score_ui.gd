class_name ScoreUI
extends Control

@export var score: Score

@onready var points_label: Label = %PointsLabel
@onready var points_gained_label: Label = %PointsGainedLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    score.points_added.connect(_on_points_added)

func _on_points_added(amount_added: int, _current_points: int):
    points_gained_label.text = "+%d" % amount_added
    animation_player.play("points_gained")

func update_points_label():
    points_label.text = "%d" % score.current_points
