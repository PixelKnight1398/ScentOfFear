# Fadeable.gd
extends StaticBody3D

@export var mesh_instance: MeshInstance3D = get_parent()

var material: Material

func _ready() -> void:
	if mesh_instance:
		material = mesh_instance.get_active_material(0).duplicate()
		mesh_instance.material_override = material

func fade_out() -> void:
	if material:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var tween := create_tween()
		tween.tween_property(material, "albedo_color:a", 0.2, 0.25)

func fade_in() -> void:
	if material:
		var tween := create_tween()
		tween.tween_property(material, "albedo_color:a", 1.0, 0.25)
		tween.finished.connect(func(): material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED)
