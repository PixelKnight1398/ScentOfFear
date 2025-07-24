# IndependentCamera.gd
extends Camera3D

# EXPORT VARIABLES
@export var target: Node3D
@export var rotation_speed: float = 0.01
@export var zoom_speed: float = 0.8
@export var min_zoom: float = 3.0
@export var max_zoom: float = 20.0
@export var initial_height: float = 4.0

# PRIVATE VARIABLES
var offset: Vector3 = Vector3.ZERO

func _ready():
	# Set the initial offset from the target
	offset = Vector3(0, initial_height, max_zoom / 2)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		# To orbit, we manually rotate the offset vector around the Y-axis
		offset = offset.rotated(Vector3.UP, -event.relative.x * rotation_speed)

	if event is InputEventMouseButton and event.is_pressed():
		var zoom_amount = 0.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_amount = -zoom_speed
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_amount = zoom_speed
		
		# To zoom, we change the length of the offset vector
		var new_length = clamp(offset.length() + zoom_amount, min_zoom, max_zoom)
		offset = offset.normalized() * new_length

func _process(delta) -> void:
	if target:
		# The camera's new position is the target's position plus the calculated offset
		global_transform.origin = target.global_transform.origin + offset
		
		# We must also manually tell the camera to always look at the target
		look_at(target.global_transform.origin, Vector3.UP)
