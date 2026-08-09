extends ItemAgent

@onready var goofy_goggles_screen_effect: GoofyGogglesEffect = get_tree().current_scene.get_node("%GoofyGogglesEffect")

func _ready() -> void:
	super._ready()

func _on_item_picked_up(carrier):
	super._on_item_picked_up(carrier)

	var character: Character = carrier.get_node("%Character")

	character.show_goggles()

	if carrier is Player:
		goofy_goggles_screen_effect.enable_goofy_goggles()

func _on_item_dropped():
	var character: Character = affected_carrier.get_node("%Character")

	character.hide_goggles()

	if affected_carrier is Player:
		goofy_goggles_screen_effect.disable_goofy_goggles()

	super._on_item_dropped()

func reset_effect():
	super.reset_effect()

	if affected_carrier:
		var character: Character = affected_carrier.get_node("%Character")

		character.hide_goggles()

		if affected_carrier is Player:
			goofy_goggles_screen_effect.disable_goofy_goggles()
