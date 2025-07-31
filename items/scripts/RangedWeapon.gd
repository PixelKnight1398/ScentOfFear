extends Weapon

var bullet_scene := preload("res://items/guns/bullet.tscn")

var player_inventory: Inventory = null # A reference to the player's inventory

var current_ammo_in_mag = 0;

func on_equipped(inventory_ref: Inventory) -> void:
	# First, run all the code from the parent's (BaseWeapon) function.
	super.on_equipped(inventory_ref)
	
	# Now, add the new, specialized logic for just this weapon.
	player_inventory = inventory_ref
	reload()

func action() -> void:
	# Find the "Muzzle" node within the currently equipped weapon.
	var muzzle: Marker3D = get_node_or_null("Muzzle")
	
	# If we couldn't find a muzzle, don't try to shoot.
	if not muzzle:
		print("Error: No Muzzle node found on the equipped weapon.")
		return

	if current_ammo_in_mag == 0:
		print("click")
	else:
		# Create an instance of our preloaded bullet scene.
		var bullet = bullet_scene.instantiate()
		get_tree().get_root().add_child(bullet)
		bullet.global_transform = muzzle.global_transform
		current_ammo_in_mag -= 1

func reload() -> void:
	if not item_data or not player_inventory:
		return

	# Figure out how much ammo is needed to top off the magazine.
	var ammo_needed = item_data.magazine_size - current_ammo_in_mag
	if ammo_needed <= 0:
		return # Magazine is already full.
	
	# Ask the player's inventory for the ammo.
	var ammo_to_refill = player_inventory.use_ammo(ammo_needed)
	
	# Add the ammo to the magazine.
	current_ammo_in_mag += ammo_to_refill
	print("Reloaded. Magazine now has ", current_ammo_in_mag, " rounds.")
