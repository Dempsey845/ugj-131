class_name NPC_ItemAwarenessArea
extends Area3D

const MAX_CHASERS: int = 3

@onready var npc: NPC = get_parent()
@onready var game_manager: GameManager = (
	get_tree().current_scene.get_node("GameManager")
)

var npcs_chasing_this_npc: Array[NPC] = []
var tracked_item: Item


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	npc.item_picked_up.connect(_on_item_picked_up)
	npc.item_dropped.connect(_on_item_dropped)


func start_npc_chase(other_npc: NPC) -> void:
	_remove_invalid_chasers()

	if not is_instance_valid(other_npc):
		return

	if other_npc == npc:
		return

	if other_npc in npcs_chasing_this_npc:
		return

	if npcs_chasing_this_npc.size() >= MAX_CHASERS:
		return

	other_npc.chase(npc)
	npcs_chasing_this_npc.append(other_npc)

	var stopped_callable: Callable = (
		_on_chaser_stopped_chasing.bind(other_npc)
	)

	if not other_npc.stopped_chasing.is_connected(
		stopped_callable
	):
		other_npc.stopped_chasing.connect(
			stopped_callable
		)


func _on_chaser_stopped_chasing(
	other_npc: NPC
) -> void:
	if other_npc not in npcs_chasing_this_npc:
		return

	npcs_chasing_this_npc.erase(other_npc)
	_disconnect_chaser(other_npc)

	call_deferred("_try_fill_chaser_slots")


func _try_fill_chaser_slots() -> void:
	if not is_instance_valid(npc.carried_item):
		return

	_remove_invalid_chasers()

	if npcs_chasing_this_npc.size() >= MAX_CHASERS:
		return

	var overlapping_bodies: Array[Node3D] = (
		get_overlapping_bodies()
	)

	overlapping_bodies.shuffle()

	for body: Node3D in overlapping_bodies:
		if npcs_chasing_this_npc.size() >= MAX_CHASERS:
			break

		if body is not NPC:
			continue

		if body == npc:
			continue

		start_npc_chase(body as NPC)


func _remove_invalid_chasers() -> void:
	for index in range(
		npcs_chasing_this_npc.size() - 1,
		-1,
		-1
	):
		var other_npc: NPC = (
			npcs_chasing_this_npc[index]
		)

		if not is_instance_valid(other_npc):
			npcs_chasing_this_npc.remove_at(index)
			continue

		if other_npc.chase_target != npc:
			_disconnect_chaser(other_npc)
			npcs_chasing_this_npc.remove_at(index)


func _on_item_picked_up() -> void:
	_disconnect_tracked_item()

	tracked_item = npc.carried_item

	if is_instance_valid(tracked_item):
		if not tracked_item.tree_exited.is_connected(
			_on_npc_item_tree_exited
		):
			tracked_item.tree_exited.connect(
				_on_npc_item_tree_exited
			)

	_try_fill_chaser_slots()


func _on_body_entered(body: Node3D) -> void:
	if body is not NPC:
		return

	if body == npc:
		return

	if not is_instance_valid(npc.carried_item):
		return

	start_npc_chase(body as NPC)


func _on_item_dropped(item: Item) -> void:
	_disconnect_tracked_item()
	_remove_invalid_chasers()

	var current_chasers: Array[NPC] = (
		npcs_chasing_this_npc.duplicate()
	)

	_clear_chaser_tracking()

	for other_npc: NPC in current_chasers:
		if not is_instance_valid(other_npc):
			continue

		if (
			game_manager.is_current_round_hot_potato
			and game_manager.round_time
				< game_manager.urgent_time
		):
			other_npc.start_fleeing(item)
		else:
			other_npc.chase_dropped_item(item)


func _on_npc_item_tree_exited() -> void:
	call_deferred(
		"_handle_npc_item_tree_exited"
	)


func _handle_npc_item_tree_exited() -> void:
	if tracked_item == null:
		return

	if (
		is_instance_valid(tracked_item)
		and tracked_item.is_inside_tree()
	):
		return

	var current_chasers: Array[NPC] = (
		npcs_chasing_this_npc.duplicate()
	)

	_clear_chaser_tracking()

	for other_npc: NPC in current_chasers:
		if not is_instance_valid(other_npc):
			continue

		if other_npc.chase_target == npc:
			other_npc.stop_chasing()

	tracked_item = null


func _disconnect_chaser(other_npc: NPC) -> void:
	if not is_instance_valid(other_npc):
		return

	var stopped_callable: Callable = (
		_on_chaser_stopped_chasing.bind(other_npc)
	)

	if other_npc.stopped_chasing.is_connected(
		stopped_callable
	):
		other_npc.stopped_chasing.disconnect(
			stopped_callable
		)


func _clear_chaser_tracking() -> void:
	for other_npc: NPC in npcs_chasing_this_npc:
		_disconnect_chaser(other_npc)

	npcs_chasing_this_npc.clear()


func _disconnect_tracked_item() -> void:
	if not is_instance_valid(tracked_item):
		tracked_item = null
		return

	if tracked_item.tree_exited.is_connected(
		_on_npc_item_tree_exited
	):
		tracked_item.tree_exited.disconnect(
			_on_npc_item_tree_exited
		)

	tracked_item = null