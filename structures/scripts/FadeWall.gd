# FadeWall.gd
extends StaticBody3D

enum State { OPAQUE, FADING, TRANSPARENT }

@onready var mesh_instance: MeshInstance3D = get_parent()
@onready var fade_timer: Timer = $FadeTimer

var material: Material
var current_state: State = State.OPAQUE

func _ready() -> void:
	if mesh_instance:
		material = mesh_instance.get_active_material(0).duplicate()
		mesh_instance.material_override = material

func fade_out() -> void:
	# Only start a fade-out tween if the wall is fully opaque.
	if current_state == State.OPAQUE and material:
		current_state = State.FADING
		
		# Enable transparency
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		var tween := create_tween()
		tween.finished.connect(func(): current_state = State.TRANSPARENT)
		tween.tween_property(material, "albedo_color:a", 0.2, 0.25)
	
	# Restart the timer every frame the wall is in the way.
	fade_timer.start()

func _on_timer_timeout() -> void:
	# Only start a fade-in tween if the wall isn't already opaque.
	if current_state != State.OPAQUE and material:
		current_state = State.FADING
		
		var tween := create_tween()
		tween.tween_property(material, "albedo_color:a", 1.0, 0.25)
		
		# When the fade-in is complete, disable transparency.
		tween.finished.connect(func():
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			current_state = State.OPAQUE
		)
