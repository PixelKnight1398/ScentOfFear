# BodyStatus.gd
class_name BodyStatus
extends Node

signal health_changed(current_health)
signal stamina_changed(current_stamina)
signal died

@export var max_health: float = 100.0
@export var max_stamina: float = 100.0

var current_health: float
var current_stamina: float

func _ready() -> void:
	current_health = max_health
	current_stamina = max_stamina

func take_damage(amount: float) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	if current_health == 0:
		died.emit()

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func use_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		stamina_changed.emit(current_stamina)
		return true
	return false

# You would add functions for status effects like bleeding here
