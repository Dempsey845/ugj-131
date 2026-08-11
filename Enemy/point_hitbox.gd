class_name PointHitbox
extends Area3D

@export var point_damage: int = 1

var _enabled: bool = true

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D):
    if _enabled == false:
        return

    if area is not PointHurtbox:
        push_warning("In-configured PointHitbox entered non PointHurtbox area!")
        return
    
    var hurtbox: PointHurtbox = area
    hurtbox.register_hit(point_damage, self)

func _force_area_check():
    var overlapping_areas = get_overlapping_areas()
    for area: Area3D in overlapping_areas:
        _on_area_entered(area)

func enable_hitbox(force_area_check: bool = true):
    _enabled = true
    if force_area_check:
     _force_area_check()

func disable_hitbox():
    _enabled = false