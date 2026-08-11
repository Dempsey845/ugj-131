extends Node


@export var bounce_velocity: float = 16.0

@onready var player: Player = get_parent()
@onready var health_hitbox: HealthHitbox = $"../HealthHitbox"

var was_falling: bool = false


func _ready() -> void:
	health_hitbox.disable_hitbox()
	health_hitbox.hit_hurtbox.connect(_on_hit_hurtbox)


func _physics_process(_delta: float) -> void:
	var is_falling: bool = (
		not player.is_on_floor()
		and player.velocity.y < 0.0
	)

	if is_falling and not was_falling:
		health_hitbox.enable_hitbox(false)

	elif not is_falling and was_falling:
		health_hitbox.disable_hitbox()

	was_falling = is_falling


func _on_hit_hurtbox(_hurtbox: HealthHurtbox) -> void:
	if not was_falling:
		return

	health_hitbox.disable_hitbox()

	player.velocity.y = bounce_velocity