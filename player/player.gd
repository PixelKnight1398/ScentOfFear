# Player.gd
extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var camera: Camera3D

# This array will keep track of all interactable items currently in range.
var nearby_interactables := []

# A dictionary to map weapon names to their scene files.
# This makes it easy to add new weapons later.
var weapon_scenes := {
	"PISTOL_1911": preload("res://items/guns/1911.tscn"),
	"RIFLE_AK47": preload("res://items/guns/AK47.tscn"),
	# "shotgun": preload("res://shotgun.tscn"), # Example for later
}

# A variable to hold the currently equipped weapon's node instance.
var current_weapon_instance: Node3D = null
# A reference to our attachment point.
@onready var weapon_attachment: Node3D = $WeaponAttachment
@onready var equipment: Equipment = $Equipment
@onready var inventory: Inventory = $Inventory

@onready var long_interact_timer: Timer = $LongInteractTimer
var long_interact_complete := false

func _ready() -> void:
	# Connect the signal so the inventory always knows when equipment changes.
	equipment.equipment_changed.connect(inventory._on_equipment_changed)

var bullet_scene := preload("res://items/guns/bullet.tscn")

func _physics_process(delta: float) -> void:
	# Store the vertical velocity from the previous frame.
	var vertical_velocity: float = velocity.y

	# Apply gravity.
	if not is_on_floor():
		vertical_velocity -= gravity * delta

	# --- Player Movement Logic ---
	# This variable will be used for both movement and rotation.
	var move_direction := Vector3.ZERO
	
	if camera:
		var input_dir := Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
		
		# --- THIS IS THE UPDATED PART ---

		# Get the camera's forward direction.
		var forward := -camera.global_transform.basis.z
		# Get the camera's right direction (this is already horizontal).
		var right := camera.global_transform.basis.x

		# Flatten the forward vector by setting its y component to 0.
		forward.y = 0
		# Re-normalize it to ensure it has a length of 1.
		forward = forward.normalized()

		# --- END OF UPDATED PART ---
		
		# Get the camera's basis vectors (its forward and right directions)
		#var forward := -camera.global_transform.basis.z
		#var right := camera.global_transform.basis.x

		# Calculate the world-space movement direction
		move_direction = (forward * input_dir.y + right * input_dir.x)

		# Calculate the new velocity based on the direction and speed.
		velocity = move_direction * speed

		# Re-apply the stored vertical velocity.
		velocity.y = vertical_velocity

		move_and_slide()

	# --- Player Rotation Logic ---
	# NEW: Check if the right mouse button is being held down.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# If aiming, use the original raycast logic to face the mouse.
		if camera:
			var space_state := get_world_3d().direct_space_state
			var mouse_pos := get_viewport().get_mouse_position()
			var query := PhysicsRayQueryParameters3D.create(
				camera.project_ray_origin(mouse_pos),
				camera.project_ray_origin(mouse_pos) + camera.project_ray_normal(mouse_pos) * 1000
			)
			var result := space_state.intersect_ray(query)

			if result:
				var look_at_point: Vector3 = result.position
				look_at_point.y = global_position.y
				look_at(look_at_point, Vector3.UP)
	else:
		# NEW: If not aiming, face the direction of movement.
		# We check if the player is actually moving to avoid snapping rotation when idle.
		if move_direction.length_squared() > 0:
			# The point to look at is simply the player's current position plus their movement direction.
			var look_at_point := global_position + move_direction
			look_at_point.y = global_position.y
			look_at(look_at_point, Vector3.UP)
			
	# After all movement code, handle the wall fading.
	check_for_obstructing_walls()

# --- Interaction Logic ---
func _unhandled_input(event: InputEvent) -> void:
	# First, check if the event that just happened was the "shoot" action being pressed.
	# We also check the *current state* of the right mouse button to ensure we are aiming.
	if event.is_action_pressed("shoot") and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# A safeguard to make sure a weapon is actually equipped.
		if current_weapon_instance:
			shoot()
			
	# When the interact button is first pressed, start the timer.
	if event.is_action_pressed("interact"):
		long_interact_complete = false
		long_interact_timer.start()

	# When the interact button is released...
	if event.is_action_released("interact"):
		# Stop the timer immediately.
		long_interact_timer.stop()
		
		if long_interact_complete:
			long_interact_complete = false
		else:
			# This is your QUICK interact logic (e.g., pick up item).
			print("Short Press Detected!")
			if not nearby_interactables.is_empty():
				var item = nearby_interactables[0]
				print(item.item_data)
				if item.item_data:
					self.pick_up(item.item_data)
					item.queue_free()

# --- Signal Functions for InteractionArea ---
func _on_interaction_area_entered(area: Area3D) -> void:
	# When an area enters our range, check if it's an "interactable" item.
	if area.get_parent().is_in_group("interactables"):
		# If it is, add it to our list of nearby items.
		nearby_interactables.append(area.get_parent())
		print("Entered range of: ", area.get_parent().name) # For debugging

func _on_interaction_area_exited(area: Area3D) -> void:
	# When an area leaves our range, check if it's an "interactable" item.
	if area.get_parent().is_in_group("interactables"):
		# If it is, remove it from our list.
		nearby_interactables.erase(area.get_parent())
		print("Left range of: ", area.get_parent().name) # For debugging

func _long_interact_timer_timeout():
	long_interact_complete = true
	
	if not nearby_interactables.is_empty():
		print("Long interact")
		var item = nearby_interactables[0]
		if item.item_data:
			self.equip(item.item_data)
			item.queue_free()

func equip(item_data: ItemData):
	# First, check if a weapon is already equipped and remove it.
	if current_weapon_instance:
		current_weapon_instance.queue_free()
		current_weapon_instance = null

	# Check if the weapon name exists in our dictionary.
	if not item_data.scene_path.is_empty():
		var new_weapon = load(item_data.scene_path)
		current_weapon_instance = new_weapon.instantiate()
		current_weapon_instance.on_equipped()
		# Add the new weapon instance as a child of the attachment point.
		# This will automatically position and rotate it with the player's hand.
		weapon_attachment.add_child(current_weapon_instance)
		
	else:
		print("Couldn't find item data to equip")

func pick_up(item_data: ItemData) -> void:
	self.inventory.add_item(item_data)

func shoot() -> void:
	# First, make sure a weapon is actually equipped.
	if not current_weapon_instance:
		return

	# Find the "Muzzle" node within the currently equipped weapon.
	# The '%' character is a shortcut for finding a unique child node.
	var muzzle: Marker3D = current_weapon_instance.get_node_or_null("Muzzle")
	
	# If we couldn't find a muzzle, don't try to shoot.
	if not muzzle:
		print("Error: No Muzzle node found on the equipped weapon.")
		return

	# Create an instance of our preloaded bullet scene.
	var bullet = bullet_scene.instantiate()

	# Add the bullet to the main game world.
	get_tree().get_root().add_child(bullet)

	# This is the key: Set the bullet's starting position and rotation
	# to be the exact same as the muzzle's world position and rotation.
	bullet.global_transform = muzzle.global_transform

func check_for_obstructing_walls() -> void:
	if not camera:
		return

	var space_state := get_world_3d().direct_space_state
	var player_pos := global_position + Vector3(0, 1, 0) # Raycast from center of player
	var camera_pos := camera.global_position

	# Create a query that starts at the camera and ends at the player.
	var query := PhysicsRayQueryParameters3D.create(camera_pos, player_pos)
	# IMPORTANT: Set the mask to ONLY check for things on the "walls" layer.
	query.collision_mask = 1 << 2 # This assumes your "walls" are on Physics Layer 3.
								 # Use 1 << 3 for Layer 4, 1 << 4 for Layer 5, etc.

	# Perform the raycast.
	var result := space_state.intersect_ray(query)

	# If the ray hit a wall...
	if result:
		var wall = result.collider
		# Check if the wall has our fade script and call the function.
		if wall.has_method("fade_out"):
			wall.fade_out()
