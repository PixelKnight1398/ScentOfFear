# Zombie.gd
extends CharacterBody3D

# State Machine
enum State { IDLE, CHASE, ATTACK }
var current_state = State.IDLE

# Settings
@export var sight_range = 15.0
@export var sight_angle = 45.0 # Degrees (half-cone)
@export var hearing_range_gunshot = 30.0
@export var speed: float = 4.0
@export var health: float = 100.0
@export var damage_amount = 10
@onready var attack_timer = $AttackTimer
var player_in_range = null # Stores the player body when close


var debug_line: ImmediateMesh
var debug_instance: MeshInstance3D

# We need a reference to the player and the navigation agent.
var player: CharacterBody3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var eyes = $RayCast3D
@onready var aggression_timer = $AggressionTimer

func _ready() -> void:
	# Get a reference to the player when the zombie spawns.
	# This assumes your player is in the "player" group.
	player = get_tree().get_first_node_in_group("player")
	
	# Create a visual debugger line
	debug_instance = MeshInstance3D.new()
	debug_line = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.RED

	debug_instance.mesh = debug_line
	debug_instance.material_override = material
	get_tree().root.add_child.call_deferred(debug_instance)

# You'll need to define gravity, just like in your player script.
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	draw_debug_path()
	# Apply gravity if the zombie is in the air.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Always look for the player
	if can_see_player():
		engage_chase()
	
	# State Logic
	match current_state:
		State.IDLE:
			# Stand still or patrol (add wander logic here later)
			velocity = Vector3.ZERO
			
		State.CHASE:
			# If we lost sight, we keep chasing until the timer runs out
			update_path_target()
			var next_point = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_point)
			velocity = direction * speed
			
			# Face direction of movement
			if direction.length() > 0.001:
				var target_look_pos = global_position + direction
				# Force the target height to match the zombie's height
				target_look_pos.y = global_position.y 
				
				look_at(target_look_pos, Vector3.UP)
			
			# If we are already close enough to attack, switch states!
			# (The Area3D signal handles this, but this is a backup check)
			if player_in_range:
				current_state = State.ATTACK
		State.ATTACK:
			# Face the player while attacking
			if player:
				var target_look_pos = player.global_position
				target_look_pos.y = global_position.y
				look_at(target_look_pos, Vector3.UP)
			
			# Stop moving (or lunge forward slightly)
			velocity = Vector3.ZERO

	move_and_slide()
	
func can_see_player() -> bool:
	if not player: return false
	
	var direction_to_player = global_position.direction_to(player.global_position)
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# 1. Check Distance
	if distance_to_player > sight_range:
		return false
		
	# 2. Check Angle (Dot Product)
	# global_transform.basis.z is the "Forward" vector of the zombie
	# Dot product returns 1.0 if looking directly at target, -1.0 if directly behind
	# We convert our angle to a dot threshold (approx 0.707 for 45 degrees)
	var forward_vector = -global_transform.basis.z 
	var angle_to_player = rad_to_deg(forward_vector.angle_to(direction_to_player))
	
	if angle_to_player > sight_angle:
		return false
	
	# 3. Check Occlusion (RayCast)
	eyes.look_at(player.global_position + Vector3(0, 1.5, 0)) # Look at player's head
	eyes.force_raycast_update() # Update immediately
	
	if eyes.is_colliding():
		var collider = eyes.get_collider()
		if collider == player:
			return true
			
	return false

# --- HEARING SYSTEM ---

# Call this function from your Player script when they shoot:
# get_tree().call_group("zombies", "hear_noise", global_position, 30.0)
func hear_noise(noise_position: Vector3, loudness: float):
	var dist = global_position.distance_to(noise_position)
	if dist <= loudness:
		engage_chase()
		

# --- STATE MANAGEMENT ---

func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body
		current_state = State.ATTACK
		attack_timer.start() # Start the attack rhythm
		
		# Optional: Instant hit on first contact? 
		# attack_player() 

func _on_attack_area_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		current_state = State.CHASE # Go back to chasing
		attack_timer.stop()

func _on_attack_timer_timeout():
	if player_in_range and current_state == State.ATTACK:
		attack_player()

func attack_player():
	print("CHOMP! Player took damage.")
	# Assuming your player has a 'take_damage' function:
	if player_in_range.has_method("take_damage"):
		player_in_range.take_damage(damage_amount)
	
	# Visual Feedback (Jiggle the zombie forward to show impact)
	create_tween().tween_property(self, "position", position + transform.basis.z * 0.2, 0.1)

func engage_chase():
	current_state = State.CHASE
	aggression_timer.start() # Reset the "give up" timer

func update_path_target():
	# Update path to player position
	nav_agent.target_position = player.global_position

func _on_memory_timer_timeout():
	# If timer runs out and we STILL can't see the player, give up
	if not can_see_player():
		current_state = State.IDLE

func draw_debug_path():
	if current_state == State.CHASE:
		debug_line.clear_surfaces()
		debug_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

		# Get the full array of points the agent wants to walk
		var path_points = nav_agent.get_current_navigation_path()

		for point in path_points:
			debug_line.surface_add_vertex(point + Vector3(0, 0.5, 0)) # Raise it up slightly

		debug_line.surface_end()

func take_damage(damage: float, direction: Vector3, force: float) -> void:
	health -= damage
	if health <= 0:
		die(direction, force)

# In Zombie.gd

var ragdoll_scene := preload("res://enemies/zombie_ragdoll.tscn")

func die(direction: Vector3, force: float) -> void:
	# Create an instance of the ragdoll scene.
	var ragdoll = ragdoll_scene.instantiate()

	# Add it to the main scene tree.
	get_tree().get_root().add_child(ragdoll)

	# Set the ragdoll's position and rotation to match the zombie's.
	ragdoll.global_transform = self.global_transform

	# Apply a force to make it fly away.
	# This force comes from the bullet's direction.
	ragdoll.apply_central_impulse(direction * force)

	# The original zombie is no longer needed.
	queue_free()
