# Inventory.gd
class_name Inventory
extends Node


@export var base_capacity: int = 10
var current_capacity: int
var items: Array[ItemData] = []

var ammo_count: int = 20

func _ready() -> void:
	current_capacity = base_capacity

## Adds an item to the inventory if there's space.
func add_item(item: ItemData) -> bool:
	if items.size() < current_capacity:
		items.append(item)
		print("Added ", item.item_name, " to inventory.")
		return true
	
	print("Inventory is full! Could not add ", item.item_name)
	return false

## This function listens for the signal from the Equipment component.
func _on_equipment_changed(current_equipment: Dictionary) -> void:
	var new_capacity = base_capacity
	
	# Loop through all equipped items to see if any provide extra capacity.
	for item in current_equipment.values():
		if item: # Check if the slot is not empty
			new_capacity += item.inventory_slots_provided
	
	current_capacity = new_capacity
	print("Inventory capacity updated to: ", current_capacity)
	
## --- AMMO FUNCTIONS ---

func get_ammo_count() -> int:
	return ammo_count

# Tries to remove ammo from the inventory and returns how much was actually taken.
func use_ammo(amount: int) -> int:
	var available_ammo = get_ammo_count()
	var amount_to_take = min(available_ammo, amount)
	
	ammo_count -= amount_to_take
	print("Used ", amount_to_take, " ammo.")
	return amount_to_take

func add_ammo(amount: int) -> void:
	ammo_count += amount
	print("Picked up ", amount, " ammo.")
