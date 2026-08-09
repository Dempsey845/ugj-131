extends ItemAgent

var hot_potato_manager: HotPotatoManager

var hold_time: float

func _ready() -> void:
	super._ready()

	hot_potato_manager = get_tree().current_scene.get_node("HotPotatoManager")

func _process(delta: float) -> void:
	if affected_carrier:
		hold_time += delta

		if hold_time >= 0.1:
			hold_time = 0

			var player_id: StringName = &"player"

			if affected_carrier is NPC:
				player_id = &"npc_%s" % affected_carrier.assigned_name.to_lower()

			hot_potato_manager.increment_player_hold_second(player_id)

func _on_item_picked_up(carrier):
	super._on_item_picked_up(carrier)
	hold_time = 0.0

func _on_item_dropped():
	super._on_item_dropped()
	hold_time = 0.0

func reset_effect():
	super.reset_effect()
	hold_time = 0

