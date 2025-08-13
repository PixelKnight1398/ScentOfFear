# SunController.gd
extends Node3D

## A gradient to control the sky color from day to night.
@export var sky_colors: GradientTexture1D
@export var world_environment: WorldEnvironment

## How fast the sun moves. A value of 0.5 is a decent speed for testing.
@export var rotation_speed: float = 0.5

func _process(delta: float) -> void:
	# Rotate the pivot
	rotate_x(deg_to_rad(rotation_speed * delta))

	# --- Update Environment ---
	if world_environment and sky_colors:
		# Calculate a value from 0.0 to 1.0 based on the sun's angle.
		# rotation.x is in radians, so we normalize it.
		var time_of_day = (rotation.x + PI) / (2.0 * PI)

		# Sample the gradient to get the correct color.
		var current_color = sky_colors.gradient.sample(time_of_day)

		# Update the environment's background and ambient light.
		world_environment.environment.background_color = current_color
		world_environment.environment.ambient_light_color = current_color
