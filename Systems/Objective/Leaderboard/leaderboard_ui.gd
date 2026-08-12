class_name LeaderboardUI
extends Control

@export var card_scene: PackedScene
@export var maximum_places: int = 3
@export var card_height: float = 84.0
@export var card_gap: float = 10.0
@export var move_duration: float = 0.32

@onready var cards_layer: Control = %CardsLayer
@onready var empty_label: Label = %EmptyLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var entries: Dictionary = {}
var cards: Dictionary = {}


func set_player_time(
	player_id: StringName,
	display_name: String,
	seconds: float,
	color: Color
) -> void:
	entries[player_id] = {
		"name": display_name,
		"seconds": maxf(seconds, 0.0),
	}

	if not cards.has(player_id):
		_create_card(player_id)

	var card: LeaderboardCard = cards[player_id]
	card.set_player_data(
		player_id,
		display_name,
		entries[player_id]["seconds"],
		color
	)
	_refresh_ranking()


func add_player(
	player_id: StringName,
	display_name: String,
	color: Color
) -> void:
	set_player_time(player_id, display_name, 0.0, color)


func remove_player(player_id: StringName) -> void:
	entries.erase(player_id)

	if cards.has(player_id):
		var card: LeaderboardCard = cards[player_id]
		cards.erase(player_id)
		card.queue_free()

	_refresh_ranking()


func clear() -> void:
	entries.clear()

	for card: LeaderboardCard in cards.values():
		card.queue_free()

	cards.clear()
	_refresh_ranking()


func get_top_players() -> Array[StringName]:
	var ranked_ids: Array[StringName] = _get_ranked_ids()
	ranked_ids.resize(mini(ranked_ids.size(), maximum_places))
	return ranked_ids


func _create_card(player_id: StringName) -> void:
	if card_scene == null:
		push_error("LeaderboardUI requires a leaderboard card scene.")
		return

	var card: LeaderboardCard = card_scene.instantiate()
	card.visible = false
	cards_layer.add_child(card)
	cards[player_id] = card


func _refresh_ranking() -> void:
	empty_label.visible = entries.is_empty()
	var ranked_ids: Array[StringName] = _get_ranked_ids()

	for player_id: StringName in cards:
		var card: LeaderboardCard = cards[player_id]
		var rank: int = ranked_ids.find(player_id)

		if rank >= 0 and rank < maximum_places:
			var target := Vector2(0.0, rank * (card_height + card_gap))
			if card.current_rank != rank or not card.visible:
				card.move_to_rank(rank, target, move_duration)
		else:
			card.hide_card(move_duration * 0.75)


func _get_ranked_ids() -> Array[StringName]:
	var ranked_ids: Array[StringName] = []
	ranked_ids.assign(entries.keys())
	ranked_ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		var a_seconds: float = entries[a]["seconds"]
		var b_seconds: float = entries[b]["seconds"]

		if is_equal_approx(a_seconds, b_seconds):
			return String(entries[a]["name"]).nocasecmp_to(
				String(entries[b]["name"])
			) < 0

		return a_seconds > b_seconds
	)
	return ranked_ids

func pop_in():
	animation_player.play("pop_in")

func pop_out():
	await get_tree().create_timer(2.0).timeout
	animation_player.play_backwards("pop_in")