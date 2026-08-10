class_name NPC_Manager
extends Node

signal npcs_created(npcs_spawned: Array[NPC])

const MAX_NPCS: int = 50

@export var npc_container: Node3D
@export var npc_spawn_points: Node3D

var npc_scene: PackedScene = preload(
	"uid://dki2wd38ewypm"
)

static var npc_names: Array[String] = [
	"Bingo",
	"Bonk",
	"Bubbles",
	"Chips",
	"Clonk",
	"Dippy",
	"Doodle",
	"Fizzle",
	"Fizz",
	"Flap",
	"Flip",
	"Flop",
	"Fumble",
	"Gizmo",
	"Goober",
	"Gumbo",
	"Jelly",
	"Jinx",
	"Loopy",
	"Mojo",
	"Muffin",
	"Noodle",
	"Pickle",
	"Pip",
	"Plop",
	"Pogo",
	"Pop",
	"Pudding",
	"Quack",
	"Ringo",
	"Scramble",
	"Skippy",
	"Splat",
	"Spork",
	"Sprout",
	"Squidge",
	"Squish",
	"Tofu",
	"Toto",
	"Truffle",
	"Waffle",
	"Wibble",
	"Wiggles",
	"Wobble",
	"Yoyo",
	"Zappy",
	"Ziggy",
	"Zippy",
	"Zonk",
	"Zoom"
]

var npcs: Array[NPC] = []


func _ready() -> void:
	_register_existing_npcs()
	assign_unique_npc_names()


func _register_existing_npcs() -> void:
	npcs.clear()

	for child: Node in npc_container.get_children():
		if child is not NPC:
			continue

		var npc: NPC = child as NPC

		npc.npc_manager = self
		npcs.append(npc)


func spawn_npcs() -> void:
	_remove_invalid_npcs()

	var npcs_spawned: Array[NPC] = []

	if npcs.size() >= MAX_NPCS:
		push_warning(
			"Cannot spawn NPCs: maximum of %d reached."
			% MAX_NPCS
		)

		npcs_created.emit(npcs_spawned)
		return

	for child: Node in npc_spawn_points.get_children():
		if npcs.size() >= MAX_NPCS:
			push_warning(
				"Stopped spawning because the maximum of %d NPCs was reached."
				% MAX_NPCS
			)
			break

		if child is not Marker3D:
			continue

		var spawn_point: Marker3D = child as Marker3D
		var npc: NPC = npc_scene.instantiate() as NPC

		if npc == null:
			push_error(
				"The NPC scene root is not an NPC."
			)
			continue

		npc_container.add_child(npc)

		npc.global_position = (
			spawn_point.global_position
		)

		npc.npc_manager = self

		npcs.append(npc)
		npcs_spawned.append(npc)

	assign_unique_npc_names()

	npcs_created.emit(npcs_spawned)


func assign_unique_npc_names() -> void:
	_remove_invalid_npcs()

	var used_names: Array[String] = []

	for npc: NPC in npcs:
		if not is_instance_valid(npc):
			continue

		if npc.assigned_name.is_empty():
			continue

		if npc.assigned_name not in used_names:
			used_names.append(npc.assigned_name)

	var available_names: Array[String] = []

	for npc_name: String in npc_names:
		if npc_name not in used_names:
			available_names.append(npc_name)

	available_names.shuffle()

	for npc: NPC in npcs:
		if not is_instance_valid(npc):
			continue

		npc.npc_manager = self

		if not npc.assigned_name.is_empty():
			continue

		if available_names.is_empty():
			push_warning(
				"No unique NPC names remain."
			)
			return

		var new_name: String = available_names.pop_back()
		npc.assign_name(new_name)


func _remove_invalid_npcs() -> void:
	for index: int in range(
		npcs.size() - 1,
		-1,
		-1
	):
		if not is_instance_valid(npcs[index]):
			npcs.remove_at(index)
