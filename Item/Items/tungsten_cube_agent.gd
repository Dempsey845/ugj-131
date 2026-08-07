extends ItemAgent

func _ready() -> void:
	super._ready()

func _on_item_picked_up(carrier):
	super._on_item_picked_up(carrier)

	carrier.move_speed_multiplier = 0.5

func _on_item_dropped():
	affected_carrier.move_speed_multiplier = 1.0

	super._on_item_dropped()

func reset_effect():
	super.reset_effect()

	if affected_carrier:
		affected_carrier.move_speed_multiplier = 1.0