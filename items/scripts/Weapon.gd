class_name Weapon
extends Node3D

@export var item_data: ItemData
var is_equipped: bool = false

func on_equipped(inventory_ref: Inventory) -> void:
	is_equipped = true
	# Get the interaction area node.
	var interaction_area: Area3D = get_node_or_null("Area3D")
	if interaction_area:
		# Disable the collision shape so it can no longer be detected.
		interaction_area.get_node("CollisionShape3D").disabled = true

func on_dropped() -> void:
	is_equipped = false
	var interaction_area: Area3D = get_node_or_null("Area3D")
	if interaction_area:
		interaction_area.get_node("CollisionShape3D").disabled = false

func action() -> void:
	pass
