class_name Score
extends Node

signal points_changed(points: int)
signal points_added(amount_added: int, current_points: int)

var _current_points: int = 0
var current_points: int:
    get():
        return _current_points
    set(value):
        _current_points = value
        points_changed.emit(value)

func add_points(amount: int):
    current_points += amount
    points_added.emit(amount, current_points)