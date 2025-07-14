# In your main world script (e.g., Main.gd)
extends Node3D

# --- EXPORTED VARIABLES ---
# This creates a slot in the Inspector to link our nodes. It's the safest method.
@export var spawn_points_container: Node3D
@export var zombie_scene: PackedScene

func _ready():
	# This line forces the navigation mesh to be visible.
	NavigationServer3D.set_debug_enabled(true)

# --- SIGNAL FUNCTIONS ---
func _on_spawn_timer_timeout() -> void:
	# First, check if the container has been linked in the editor.
	if not spawn_points_container:
		print("Error: Spawn Points Container not assigned in the Inspector!")
		return

	# Get a list of all children from our container node.
	var spawn_points: Array = spawn_points_container.get_children()
	
	# Check if the container actually has any spawn points in it.
	if not spawn_points.is_empty():
		# This check is important! Make sure a zombie scene is assigned.
		if not zombie_scene:
			print("Error: Zombie Scene not assigned in the Inspector!")
			return

		var zombie = zombie_scene.instantiate()

		# Pick a random spawn point from the list.
		var spawn_point = spawn_points.pick_random()
		
		# Add the zombie as a child of this main node.
		add_child(zombie)
		
		# This line should now work without errors.
		zombie.global_position = spawn_point.global_position
