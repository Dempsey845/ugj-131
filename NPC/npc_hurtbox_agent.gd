extends Node

@onready var character_point_hurtbox: PointHurtbox = $"../CharacterPointHurtbox"
@onready var npc: NPC = get_parent()

func _ready() -> void:
    character_point_hurtbox.hurtbox_hit.connect(_on_hurtbox_hit)

func _on_hurtbox_hit(hitbox: PointHitbox):
    npc.flee_from_position(hitbox.global_position)