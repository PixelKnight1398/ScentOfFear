# AngledTopDownCamera.gd
extends Camera3D

# EXPORT VARIABLES
@export var target: Node3D
@export var rotation_speed: float = 0.01
@export var zoom_speed: float = 0.8
@export var min_zoom: float = 3.0
@export var max_zoom: float = 25.0

## This is the key variable. It controls the fixed angle of the camera.
## (X:0, Y:1, Z:1) means for every 1 unit away, it goes 1 unit up (a 45-degree angle).
## For a more top-down view, you could use (X:0, Y:2, Z:1).
@export var camera_angle := Vector3(0, 2, 1)

# PRIVATE VARIABLES
var offset_direction: Vector3
var current_zoom: float = 15.0


func _ready() -> void:
	# Make sure our angle vector is normalized so its length is 1.
	offset_direction = camera_angle.normalized()
	current_zoom = (min_zoom + max_zoom) / 2
	_process(0) # Force an update on the first frame.


func _unhandled_input(event: InputEvent) -> void:
	# --- Orbit Logic ---
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		# Rotate the fixed angle direction vector around the target.
		offset_direction = offset_direction.rotated(Vector3.UP, -event.relative.x * rotation_speed)

	# --- Zoom Logic ---
	if event is InputEventMouseButton and event.is_pressed():
		var zoom_amount = 0.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_amount = zoom_speed
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_amount = -zoom_speed
		
		# Modify the zoom distance.
		current_zoom = clamp(current_zoom - zoom_amount, min_zoom, max_zoom)


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	# --- Position Calculation ---
	# The final position is the target's position plus our angled offset multiplied by the zoom.
	global_position = target.global_position + (offset_direction * current_zoom)
	
	# Always look at the target.
	look_at(target.global_position)
