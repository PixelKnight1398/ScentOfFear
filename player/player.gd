extends CharacterBody3D

# --- State Management ---
enum CameraState { FIRST_PERSON, THIRD_PERSON }
@export var current_state: CameraState = CameraState.THIRD_PERSON

@export_group("Settings")
@export var speed: float = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export_group("References")
# Assign the camera currently being used (update this when switching modes)
@export var camera: Camera3D

# --- Inventory / Equipment ---
var nearby_interactables := []
var current_weapon_instance: Node3D = null

@onready var equipment: Equipment = $Equipment
@onready var inventory: Inventory = $Inventory

@export_group("Arm Rigs")
@export var arms_idle: Node3D
@export var arms_pistol: Node3D
@export var arms_rifle: Node3D
@export var arms_shotgun: Node3D
@export var arms_energy: Node3D

@export_group("Attachment Points")
@export var point_pistol: Marker3D
@export var point_rifle: Marker3D
@export var point_shotgun: Marker3D
@export var point_energy: Marker3D

@onready var long_interact_timer: Timer = $LongInteractTimer
var long_interact_complete := false

func _ready() -> void:
	equipment.equipment_changed.connect(inventory._on_equipment_changed)

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Get Input
	var input_dir := Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	var move_direction := Vector3.ZERO

	# 3. Handle Movement based on State
	match current_state:
		CameraState.FIRST_PERSON:
			move_direction = _get_first_person_movement(input_dir)
			# NOTE: We do NOT handle rotation here for FPS. 
			# The Camera script handles the mouse rotation for the body.
			
		CameraState.THIRD_PERSON:
			if camera:
				move_direction = _get_third_person_movement(input_dir)
				_handle_third_person_rotation(move_direction)

	# 4. Apply Velocity
	var vertical_velocity = velocity.y # Preserve gravity
	velocity = move_direction * speed
	velocity.y = vertical_velocity
	move_and_slide()
	
	# 5. Check Walls (Only needed for Third Person typically, but fine to keep)
	if current_state == CameraState.THIRD_PERSON:
		check_for_obstructing_walls()

# --- Movement Logic ---

func _get_first_person_movement(input_dir: Vector2) -> Vector3:
	# In FPS, we move relative to the PLAYER'S local transform, not the camera.
	# Because the Camera script rotates the Player Body, "transform.basis" is always correct.
	var forward_vector = -transform.basis.z
	var right_vector = transform.basis.x
	
	var direction = (forward_vector * input_dir.y + right_vector * input_dir.x)
	return direction.normalized()

func _get_third_person_movement(input_dir: Vector2) -> Vector3:
	# In TPS, we move relative to the CAMERA'S view.
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x

	forward.y = 0
	forward = forward.normalized()
	right.y = 0
	right = right.normalized()

	return (forward * input_dir.y + right * input_dir.x).normalized()

func _handle_third_person_rotation(move_direction: Vector3) -> void:
	# Your existing logic: Rotate towards mouse if aiming, else rotate towards movement
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
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
		if move_direction.length_squared() > 0:
			var look_at_point := global_position + move_direction
			look_at_point.y = global_position.y
			look_at(look_at_point, Vector3.UP)

# --- State Switching Helper ---
func set_camera_state(new_state: CameraState, new_camera: Camera3D):
	current_state = new_state
	camera = new_camera
	
	# Optional: If switching to FPS, align player body to camera look direction immediately
	# to prevent snapping.
	if current_state == CameraState.FIRST_PERSON:
		var look_dir = -new_camera.global_transform.basis.z
		look_dir.y = 0
		if look_dir.length() > 0:
			look_at(global_position + look_dir, Vector3.UP)

# --- Interaction Logic (Unchanged) ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		# Allow shooting in FPS mode freely, or in TPS mode only if aiming
		if current_state == CameraState.FIRST_PERSON or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			use_weapon()
		
	if event.is_action_pressed("reload"):
		if current_weapon_instance and current_weapon_instance.has_method("reload"):
			current_weapon_instance.reload()
			
	if event.is_action_pressed("interact"):
		long_interact_complete = false
		long_interact_timer.start()

	if event.is_action_released("interact"):
		long_interact_timer.stop()
		if long_interact_complete:
			long_interact_complete = false
		else:
			if not nearby_interactables.is_empty():
				var item = nearby_interactables[0]
				if item.item_data:
					self.pick_up(item.item_data)
					item.queue_free()

func _on_interaction_area_entered(area: Area3D) -> void:
	if area.get_parent().is_in_group("interactables"):
		nearby_interactables.append(area.get_parent())

func _on_interaction_area_exited(area: Area3D) -> void:
	if area.get_parent().is_in_group("interactables"):
		nearby_interactables.erase(area.get_parent())

func _long_interact_timer_timeout():
	long_interact_complete = true
	if not nearby_interactables.is_empty():
		var item = nearby_interactables[0]
		if item.item_data:
			self.equip(item.item_data)
			item.queue_free()

# --- Equipment Logic (Unchanged) ---
func equip(item_data: ItemData):
	match item_data.item_type:
		ItemData.ItemType.WEAPON:
			_equip_weapon(item_data)
		ItemData.ItemType.APPAREL:
			_equip_apparel(item_data)
		_:
			print("Cannot equip item of this type")

func _equip_weapon(weapon_data: ItemData):
	if current_weapon_instance:
		current_weapon_instance.queue_free()
		current_weapon_instance = null

	if weapon_data and weapon_data.scene_path:
		var new_weapon_scene = load(weapon_data.scene_path)
		current_weapon_instance = new_weapon_scene.instantiate()
		
		hide_all_arms()
		
		match weapon_data.weapon_type:
			weapon_data.WeaponType.PISTOL:
				point_pistol.add_child(current_weapon_instance)
				arms_pistol.visible = true
			weapon_data.WeaponType.RIFLE:
				point_rifle.add_child(current_weapon_instance)
				arms_rifle.visible = true
			_:
				print("Unknown Weapon Type")

		if current_weapon_instance.has_method("on_equipped"):
			current_weapon_instance.on_equipped(inventory)

func hide_all_arms():
	arms_idle.visible = false
	arms_pistol.visible = false
	arms_rifle.visible = false
	#arms_shotgun.visible = false
	#arms_energy.visible = false

func _equip_apparel(apparel_data: ItemData):
	equipment.equip_item(apparel_data, apparel_data.equipment_slot)

func pick_up(item_data: ItemData) -> void:
	self.inventory.add_item(item_data)

func use_weapon() -> void:
	if not current_weapon_instance:
		return
	current_weapon_instance.action()

func check_for_obstructing_walls() -> void:
	if not camera: return
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, global_position)
	query.collision_mask = 1 << 2 
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	if result:
		var wall_piece = result.collider
		var wall_section = wall_piece.get_parent()
		if wall_section and wall_section.has_method("fade_out"):
			wall_section.fade_out()
