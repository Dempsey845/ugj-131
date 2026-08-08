class_name SlippyArea
extends Area3D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
    if body is Player or body is NPC:
        if body.has_method("enter_slippery_area"):
            body.enter_slippery_area()

func _on_body_exited(body: Node3D):
    if body is Player or body is NPC:
        if body.has_method("exit_slippery_area"):
            body.exit_slippery_area()