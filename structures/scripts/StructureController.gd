extends Node3D

@export var floor_levels: Array[Node3D]

# An array to track the active state of each floor.
var active_floors := []

func _ready() -> void:
	# Initialize the active_floors array with "false" for every level.
	active_floors.resize(floor_levels.size())
	active_floors.fill(false)

func _on_player_entered_floor(body: Node3D, floor_index: int) -> void:
	if body.is_in_group("player"):
		# Set the flag for this floor to true.
		active_floors[floor_index] = true
		# Update the visibility for the whole house.
		_update_floor_visibility()

func _on_player_exited_floor(body: Node3D, floor_index: int) -> void:
	if body.is_in_group("player"):
		# Set the flag for this floor to false.
		active_floors[floor_index] = false
		# Update the visibility for the whole house.
		_update_floor_visibility()

func _update_floor_visibility() -> void:
	var highest_active_floor = -1
	# Find the highest floor the player is currently on.
	for i in range(active_floors.size() - 1, -1, -1):
		if active_floors[i]:
			highest_active_floor = i
			break

	# If highest_active_floor is -1, the player is outside. Show everything.
	if highest_active_floor == -1:
		for floor_node in floor_levels:
			floor_node.show()
			_set_visibility_mode_for_children(floor_node, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
		return

	# Otherwise, update visibility based on the highest active floor.
	var roof_index = floor_levels.size() - 1
	for i in floor_levels.size():
		var floor_node = floor_levels[i]
		if i > highest_active_floor:
			if i == roof_index: # Is this the roof?
				_set_visibility_mode_for_children(floor_node, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
			else: # It's just an upper floor
				floor_node.hide()
		else:
			floor_node.show()
			_set_visibility_mode_for_children(floor_node, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)

# Helper function to find all MeshInstance3D children and set their shadow mode.
func _set_visibility_mode_for_children(start_node: Node, mode: GeometryInstance3D.ShadowCastingSetting) -> void:
	for child in start_node.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = mode
		if child.get_child_count() > 0:
			_set_visibility_mode_for_children(child, mode)
