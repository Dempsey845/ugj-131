extends ItemAgent

@onready var shoe_box: ShoeBox = $"../Visuals/ShoeBox"

func _ready() -> void:
	super._ready()

func _on_item_picked_up(carrier):
	super._on_item_picked_up(carrier)

	var character: Character = carrier.get_node("%Character")
	character.show_shoes()

	carrier.set_ice_movement_enabled(true)

	shoe_box.close_lid()

func _on_item_dropped():
	var character: Character = affected_carrier.get_node("%Character")
	character.hide_shoes()

	affected_carrier.set_ice_movement_enabled(false)
	
	super._on_item_dropped()

	shoe_box.open_lid()

func reset_effect():
	super.reset_effect()

	if affected_carrier:
		affected_carrier.set_ice_movement_enabled(false)

		var character: Character = affected_carrier.get_node("%Character")
		character.hide_shoes()
