# FadeController.gd
extends Node3D

@onready var fade_timer: Timer = $FadeTimer
var is_faded := false

# The player's raycast will call this function.
func fade_out() -> void:
	if not is_faded:
		is_faded = true
		# Loop through all children and tell them to fade out.
		for child in get_children():
			if child.has_method("fade_out"):
				child.fade_out()
	
	# Restart the timer to keep the wall section transparent.
	fade_timer.start()

func _on_timer_timeout() -> void:
	is_faded = false
	# Loop through all children and tell them to fade back in.
	for child in get_children():
		if child.has_method("fade_in"):
			child.fade_in()
