# ItemData.gd
class_name ItemData
extends Resource

## The name that will be displayed in the UI.
@export var item_name: String = "Item"
@export_file("*.tscn") var scene_path: String
