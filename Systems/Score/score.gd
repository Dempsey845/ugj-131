class_name Score
extends Node

signal points_changed(points: int)
signal points_added(amount_added: int, current_points: int)
signal points_removed(amount_removed: int, current_points: int)

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

func remove_points(amount: int):
    var points_to_remove: int = amount
    if current_points - amount < 0:
        points_to_remove = current_points

    current_points -= points_to_remove  
    current_points = max(current_points, 0)      
    points_removed.emit(points_to_remove, current_points)