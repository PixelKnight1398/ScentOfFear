# Bullet.gd
extends Area3D

var speed: float = 200
var selfDeleteTimer: int = 200

# This function runs every physics frame.
func _physics_process(delta: float) -> void:
	# Move the bullet forward along its own local -Z axis.
	global_position += -global_transform.basis.z * speed * delta
	selfDeleteTimer-= 1
	if selfDeleteTimer <= 0:
		queue_free()  

# This function will run when the bullet's Area3D collides with a PhysicsBody3D.
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		# If the body we hit has a "take_damage" function...
		if body.has_method("take_damage"):
			var damage = 25.0
			var force = 50.0
			# Get the bullet's forward direction.
			var direction = -global_transform.basis.z
			body.take_damage(damage, direction, force)

		queue_free() # Destroy the bullet.
