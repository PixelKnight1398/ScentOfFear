# Player.gd
extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var camera: Camera3D

# This array will keep track of all interactable items currently in range.
var nearby_interactables := []

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
		use_weapon()
		
	if event.is_action_pressed("reload"):
		if current_weapon_instance and current_weapon_instance.has_method("reload"):
			current_weapon_instance.reload()
			
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

# This is now the main entry point for equipping any item.
func equip(item_data: ItemData):
	# Use a match statement to check the item's type.
	match item_data.item_type:
		ItemData.ItemType.WEAPON:
			_equip_weapon(item_data)
		ItemData.ItemType.APPAREL:
			_equip_apparel(item_data)
		_:
			print("Cannot equip item of this type: ", item_data.item_name)


# This function now handles ONLY instantiating weapon models.
func _equip_weapon(weapon_data: ItemData):
	# First, check if a weapon is already equipped and remove it.
	if current_weapon_instance:
		current_weapon_instance.queue_free()
		current_weapon_instance = null

	# Check if the weapon has a scene to instance.
	if weapon_data and weapon_data.scene_path:
		var new_weapon_scene = load(weapon_data.scene_path)
		current_weapon_instance = new_weapon_scene.instantiate()
		
		# Add the new weapon instance to the attachment point.
		weapon_attachment.add_child(current_weapon_instance)
		
		# Tell the weapon it's been equipped so it can run its own setup.
		if current_weapon_instance.has_method("on_equipped"):
			current_weapon_instance.on_equipped(inventory)
	else:
		print("Couldn't find scene path to equip weapon: ", weapon_data.item_name)


# This new function handles ONLY apparel data.
func _equip_apparel(apparel_data: ItemData):
	# Simply tell the Equipment component to handle this item.
	# The Equipment component will put the data in the correct slot.
	equipment.equip_item(apparel_data, apparel_data.equipment_slot)

func pick_up(item_data: ItemData) -> void:
	self.inventory.add_item(item_data)

func use_weapon() -> void:
	# First, make sure a weapon is actually equipped.
	if not current_weapon_instance:
		return
		
	current_weapon_instance.action()

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
