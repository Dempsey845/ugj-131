class_name PlayerItemAwarenessArea
extends Area3D

@export var item_pickup_area: PlayerItemPickupArea

@onready var player: Player = get_parent()

var npcs_chasing_player: Array[NPC]

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	item_pickup_area.item_picked_up.connect(_on_item_picked_up)
	item_pickup_area.item_dropped.connect(_on_item_dropped)

func start_npc_chase(npc: NPC):
	npc.chase(player)
	npcs_chasing_player.append(npc)

func _on_item_picked_up():
	var overlapping_bodies: Array[Node3D] = get_overlapping_bodies()

	for body: Node3D in overlapping_bodies:
		if body is not NPC:
			continue
		
		start_npc_chase(body as NPC)

	item_pickup_area.current_item.tree_exited.connect(_on_current_item_tree_exited)

func _on_item_dropped(item: Item):
	if !is_instance_valid(item):
		for npc in npcs_chasing_player:
			npc.stop_chasing()

		return

	for npc in npcs_chasing_player:
		npc.chase_dropped_item(item)
	
	npcs_chasing_player.clear()
	
	item.tree_exited.disconnect(_on_current_item_tree_exited) 

func _on_body_entered(body: Node3D):
	if body is not NPC:
		return
	
	if !item_pickup_area.does_player_have_item():
		return
	
	var npc: NPC = body

	start_npc_chase(npc)

func _on_current_item_tree_exited():
	for npc in npcs_chasing_player:
		npc.stop_chasing()
