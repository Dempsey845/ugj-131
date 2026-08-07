class_name CountdownUI
extends Control

@export var objective: Objective

@onready var countdown_label: Label = $CountdownLabel

var time: float

func _ready() -> void:
    objective.objective_started.connect(_on_objective_started)

func _process(delta: float) -> void:
    if time > 0.0:
        time -= delta
        countdown_label.text = "%d" % int(time)

        if time <= 0.0:
            countdown_label.text = ""
            objective.stop_objective()
            

func start_countdown(from: int):
    time = from
    countdown_label.text = "%d" % int(time)

func _on_objective_started(item_data: ItemData):
    start_countdown(item_data.seconds_to_collect)