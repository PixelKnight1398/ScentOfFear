class_name Apparel
extends Node3D

@export var item_data: ItemData

func _physics_process(delta: float) -> void:
	rotate(Vector3.UP, 0.05)
