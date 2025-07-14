# zombie_ragdoll.gd
extends RigidBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# The _ready function runs once when the node is created and added to the scene.
func _ready() -> void:
	# This is the key fix:
	# Get the currently active material, create a unique duplicate of it,
	# and assign that new copy back to this specific mesh instance.
	mesh_instance.material_override = mesh_instance.get_active_material(0).duplicate()

func _on_timer_timeout() -> void:
	# We get the material from the override slot now, which we know is unique.
	var material = mesh_instance.material_override
	
	if not material:
		queue_free()
		return

	var tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 1.0)
	
	await tween.finished
	queue_free()
