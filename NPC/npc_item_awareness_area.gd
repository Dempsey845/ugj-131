class_name NPC_ItemAwarenessArea
extends Area3D

@onready var npc: NPC = get_parent()

var npcs_chasing_this_npc: Array[NPC]

func _ready() -> void:
    body_entered.connect(_on_body_entered)

    npc.item_picked_up.connect(_on_item_picked_up)
    npc.item_dropped.connect(_on_item_dropped)

func start_npc_chase(other_npc: NPC):
    other_npc.chase(npc)
    npcs_chasing_this_npc.append(other_npc)

func _on_item_dropped(item: Item):
    for other_npc in npcs_chasing_this_npc:
        other_npc.chase_dropped_item(item)
    
    npcs_chasing_this_npc.clear()

func _on_item_picked_up():
    var overlapping_bodies: Array[Node3D] = get_overlapping_bodies()

    for body: Node3D in overlapping_bodies:
        if body is not NPC:
            continue

        if body == npc:
            continue
        
        start_npc_chase(body as NPC)

func _on_body_entered(body: Node3D):
    if body is not NPC:
        return
    
    if body == npc:
        return
    
    if npc.carried_item == null:
        return
    
    var other_npc: NPC = body

    start_npc_chase(other_npc)
