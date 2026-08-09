class_name GoofyGogglesEffect
extends ColorRect

var goggles_tween: Tween

func enable_goofy_goggles() -> void:
	show()
	_animate_goggles_intensity(1.0)


func disable_goofy_goggles() -> void:
	await _animate_goggles_intensity(0.0).finished
	hide()


func _animate_goggles_intensity(target: float) -> Tween:
	if goggles_tween:
		goggles_tween.kill()

	goggles_tween = create_tween()
	goggles_tween.set_trans(Tween.TRANS_SINE)
	goggles_tween.set_ease(Tween.EASE_IN_OUT)

	goggles_tween.tween_property(
		material,
		"shader_parameter/intensity",
		target,
		0.45
	)

	return goggles_tween