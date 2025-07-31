# ItemData.gd
class_name ItemData
extends Resource

enum ItemType { WEAPON, APPAREL, CONSUMABLE }

## The name that will be displayed in the UI.
@export var item_name: String = "Item"
@export_file("*.tscn") var scene_path: String

@export var item_type: ItemType = ItemType.WEAPON
@export var equipment_slot: Equipment.Slot
@export var secondary_equipment_slot: Equipment.Slot
