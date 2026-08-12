class_name ScoreUI
extends Control

@export var score: Score

@onready var points_label: Label = %PointsLabel
@onready var points_gained_label: Label = %PointsGainedLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var name_label: Label = %NameLabel

func _ready() -> void:
    score.points_added.connect(_on_points_added)
    score.points_removed.connect(_on_points_removed)
    name_label.text = SceneManager.player_name

func _on_points_added(amount_added: int, _current_points: int):
    points_gained_label.text = "+%d" % amount_added
    animation_player.play("points_gained")

func _on_points_removed(amount_removed: int, _current_points: int):
    points_gained_label.text = "-%d" % amount_removed
    animation_player.play("points_gained")

func update_points_label():
    points_label.text = "%d" % score.current_points
