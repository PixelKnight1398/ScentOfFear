extends Camera3D

# --- References ---
@export_group("Targets")
@export var player_body: CharacterBody3D
## The exact name of the node inside the player to snap to.
@export var head_target_name: String = "CameraMount"

var _head_target_node: Node3D

# --- Settings ---
@export_group("Settings")
@export var mouse_sensitivity: float = 0.003
@export var vertical_limit: float = 1.57

# We store the camera's X rotation (Pitch) here to prevent drift.
var _cam_pitch: float = 0.0

@export_group("Masking")
@export_flags_3d_render var player_mesh_layer: int = 2

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cull_mask = cull_mask & ~player_mesh_layer
	
	if player_body:
		# CHANGED: Use find_child with recursive=true (the 'true' param)
		# This finds "CameraMount" even if it's buried deep inside the player.
		_head_target_node = player_body.find_child(head_target_name, true, false)
		
		if not _head_target_node:
			push_error("Camera Error: Could not find '" + head_target_name + "' anywhere inside " + player_body.name)
		else:
			print("Camera successfully snapped to: ", _head_target_node.name)

func _input(event: InputEvent) -> void:
	# Ignore input if not the active camera
	if not current:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_look(event)
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _handle_look(event: InputEventMouseMotion) -> void:
	if player_body:
		# Rotate the Player Body (Yaw)
		player_body.rotate_y(-event.relative.x * mouse_sensitivity)
		
	# Update our internal pitch variable
	_cam_pitch -= event.relative.y * mouse_sensitivity
	_cam_pitch = clamp(_cam_pitch, -vertical_limit, vertical_limit)

func _physics_process(_delta: float) -> void:
	if _head_target_node:
		# 1. Snap Position
		global_position = _head_target_node.global_position
		
		# 2. Force Rotation
		# We construct a new rotation from scratch:
		# X = Our internal Pitch
		# Y = The Player's current Yaw
		# Z = 0 (Strictly prevent rolling)
		global_rotation = Vector3(_cam_pitch, player_body.global_rotation.y, 0)
