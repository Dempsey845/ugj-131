class_name PlayerItemAwarenessArea
extends Area3D

const MAX_CHASERS: int = 5

@export var item_pickup_area: PlayerItemPickupArea

@onready var player: Player = get_parent()

var npcs_chasing_player: Array[NPC] = []
var tracked_item: Item


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	item_pickup_area.item_picked_up.connect(
		_on_item_picked_up
	)

	item_pickup_area.item_dropped.connect(
		_on_item_dropped
	)


func start_npc_chase(npc: NPC) -> void:
	_remove_invalid_chasers()

	if not is_instance_valid(npc):
		return

	if npc in npcs_chasing_player:
		return

	if npcs_chasing_player.size() >= MAX_CHASERS:
		return

	npc.chase(player)
	npcs_chasing_player.append(npc)


func _remove_invalid_chasers() -> void:
	for index in range(
		npcs_chasing_player.size() - 1,
		-1,
		-1
	):
		var npc: NPC = npcs_chasing_player[index]

		if (
			not is_instance_valid(npc)
			or npc.chase_target != player
		):
			npcs_chasing_player.remove_at(index)


func _on_item_picked_up() -> void:
	_disconnect_tracked_item()

	tracked_item = item_pickup_area.current_item

	if is_instance_valid(tracked_item):
		tracked_item.tree_exited.connect(
			_on_current_item_tree_exited
		)

	var overlapping_bodies: Array[Node3D] = (
		get_overlapping_bodies()
	)

	for body: Node3D in overlapping_bodies:
		if npcs_chasing_player.size() >= MAX_CHASERS:
			break

		if body is not NPC:
			continue

		start_npc_chase(body as NPC)


func _on_item_dropped(item: Item) -> void:
	_disconnect_tracked_item()
	_remove_invalid_chasers()

	if not is_instance_valid(item):
		for npc: NPC in npcs_chasing_player:
			if not is_instance_valid(npc):
				continue

			if npc.chase_target == player:
				npc.stop_chasing()

		npcs_chasing_player.clear()
		return

	for npc: NPC in npcs_chasing_player:
		if not is_instance_valid(npc):
			continue

		npc.chase_dropped_item(item)

	npcs_chasing_player.clear()


func _on_body_entered(body: Node3D) -> void:
	if body is not NPC:
		return

	if not item_pickup_area.does_player_have_item():
		return

	start_npc_chase(body as NPC)


func _on_current_item_tree_exited() -> void:
	for npc: NPC in npcs_chasing_player:
		if not is_instance_valid(npc):
			continue

		if npc.chase_target == player:
			npc.stop_chasing()

	npcs_chasing_player.clear()
	tracked_item = null


func _disconnect_tracked_item() -> void:
	if not is_instance_valid(tracked_item):
		tracked_item = null
		return

	if tracked_item.tree_exited.is_connected(
		_on_current_item_tree_exited
	):
		tracked_item.tree_exited.disconnect(
			_on_current_item_tree_exited
		)

	tracked_item = null