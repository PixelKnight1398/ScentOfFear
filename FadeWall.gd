# FadeWall.gd
extends StaticBody3D

@onready var mesh_instance: MeshInstance3D = get_parent()
@onready var timer: Timer = $FadeTimer

var material: StandardMaterial3D
var is_faded := false

func _ready() -> void:
	# Each wall gets its own unique material instance to fade independently.
	if mesh_instance:
		material = mesh_instance.get_active_material(0).duplicate()
		mesh_instance.material_override = material
		# Set material to allow transparency
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func fade_out() -> void:
	if not is_faded and material:
		is_faded = true
		var tween := create_tween()
		tween.tween_property(material, "albedo_color:a", 0.2, 0.25)
	# Every time the wall is in the way, we restart its fade-in timer.
	timer.start()

func _on_timer_timeout() -> void:
	# If the timer finishes, it means the player is no longer behind this wall.
	if is_faded and material:
		is_faded = false
		var tween := create_tween()
		tween.tween_property(material, "albedo_color:a", 1.0, 0.25)
		
