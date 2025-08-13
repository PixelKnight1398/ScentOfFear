# FloorTrigger.gd
extends Area3D

## In the Inspector, drag all floors and the roof you want to hide into this array.
@export var upper_floors: Array[Node3D]

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_set_visibility_mode_for_children(get_parent(), GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
		# Loop through the list of all floors to hide.
		for floor_node in upper_floors:
			print(floor_node.name)
			# Apply the shadows-only effect to every floor in the list.
			_set_visibility_mode_for_children(floor_node, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		# When the player leaves, show all floors and reset their shadow casting.
		for floor_node in upper_floors:
			#floor_node.show()
			_set_visibility_mode_for_children(floor_node, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)

# Helper function to find all MeshInstance3D children and set their shadow mode.
func _set_visibility_mode_for_children(start_node: Node, mode: GeometryInstance3D.ShadowCastingSetting) -> void:
	# This function recursively finds all MeshInstance3D nodes and sets their properties.
	for child in start_node.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = mode
		
		if child.get_child_count() > 0:
			_set_visibility_mode_for_children(child, mode)
