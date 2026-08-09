extends Label3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var hot_potato_manager: HotPotatoManager

func _ready() -> void:
    hot_potato_manager = get_tree().current_scene.get_node("HotPotatoManager")
    hot_potato_manager.player_time_reset.connect(_on_player_time_reset)

func _on_player_time_reset(player_id: StringName, time_lossed: float):
    if hot_potato_manager.player_id_to_instance[player_id] == get_parent():
        text = str(time_lossed)
        animation_player.play("pop_in")