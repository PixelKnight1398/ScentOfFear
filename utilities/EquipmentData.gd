# ItemData.gd
class_name EquipmentData
extends Resource

## The name that will be displayed in the UI.
@export var item_name: String = "Item"

## A list of valid slots this item can be equipped in.
## Leave empty if it's not an equippable item.
@export var valid_slots: Array[Equipment.Slot]

## How many inventory slots this item provides when equipped (e.g., for a backpack).
@export var inventory_slots_provided: int = 0
