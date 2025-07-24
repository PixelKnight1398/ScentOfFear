# Zombie.gd
extends CharacterBody3D

@export var speed: float = 4.0
@export var health: float = 100.0

# We need a reference to the player and the navigation agent.
var player: CharacterBody3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	# Get a reference to the player when the zombie spawns.
	# This assumes your player is in the "player" group.
	player = get_tree().get_first_node_in_group("player")

# You'll need to define gravity, just like in your player script.
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	# Apply gravity if the zombie is in the air.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- The rest of your navigation logic ---
	if player:
		nav_agent.target_position = player.global_position
		
		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		var move_direction: Vector3 = (next_path_position - global_position).normalized()
		
		# Set horizontal velocity (Y is handled by gravity).
		velocity.x = move_direction.x * speed
		velocity.z = move_direction.z * speed

		move_and_slide()
		
		var look_at_point: Vector3 = player.global_position
		look_at_point.y = global_position.y
		look_at(look_at_point, Vector3.UP)

func take_damage(damage: float, direction: Vector3, force: float) -> void:
	health -= damage
	if health <= 0:
		die(direction, force)

# In Zombie.gd

var ragdoll_scene := preload("res://zombie_ragdoll.tscn")

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
