# Equipment.gd
class_name Equipment
extends Node

## A signal to announce that the player's equipment has changed.
signal equipment_changed(current_equipment)

## An enum for all possible equipment slots. This prevents typos.
enum Slot { NONE, HEAD, CHEST, LEGS, BACKPACK, RIGHT_HAND, LEFT_HAND, FEET }

## A dictionary to hold the currently worn items.
@export var equipped_items: Dictionary = {
	Slot.NONE: null,
	Slot.HEAD: null,
	Slot.CHEST: null,
	Slot.LEGS: null,
	Slot.BACKPACK: null,
	Slot.RIGHT_HAND: null,
	Slot.LEFT_HAND: null,
	Slot.FEET: null
}

## Tries to equip an item to a specific slot.
func equip_item(item: EquipmentData, slot: Slot) -> void:
	# You would add logic here to check if the item is valid for the slot.
	equipped_items[slot] = item
	print("Equipped ", item.item_name, " to ", Slot.keys()[slot])
	
	# Announce that the equipment has changed.
	equipment_changed.emit(equipped_items)

## Tries to unequip an item from a slot.
func unequip_item(slot: Slot) -> EquipmentData:
	var item = equipped_items[slot]
	if item:
		equipped_items[slot] = null
		print("Unequipped ", item.item_name)
		equipment_changed.emit(equipped_items)
	return item
