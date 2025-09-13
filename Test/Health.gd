extends Node

signal died
signal health_changed(new_health)

@export var max_health: int = 100
var current_health: int = 100

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health)

	if current_health <= 0:
		died.emit()
