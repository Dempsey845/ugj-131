class_name NPC_Manager
extends Node

@export var npc_container: Node3D

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

var npcs: Array[NPC]

func _ready() -> void:
	for child in npc_container.get_children():
		if child is NPC:
			npcs.append(child)

	assign_unique_npc_names()

func assign_unique_npc_names() -> void:
	if npcs.size() > npc_names.size():
		push_warning(
			"Not enough unique names! %d NPCs but only %d names."
			% [npcs.size(), npc_names.size()]
		)
		return

	var available_names: Array[String] = npc_names.duplicate()
	available_names.shuffle()

	for i: int in npcs.size():
		if not is_instance_valid(npcs[i]):
			continue

		npcs[i].assign_name(available_names[i])