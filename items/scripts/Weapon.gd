# Weapon.gd
extends Node3D

## Defines a list of weapon types that will appear as a dropdown in the Inspector.
## You can add any weapon names you want to this list.
enum WeaponType {
	PISTOL_1911,
	RIFLE_AK47,
	SHOTGUN,
	RIFLE,
	GRENADE_LAUNCHER
}

## This creates a variable that you can set from the dropdown menu in the editor.
@export var weapon_to_give: WeaponType = WeaponType.PISTOL_1911


# This function is called by the player.
func interact(interactor: Node3D) -> void:
	# We pass the weapon's name, converted from the enum to a string.
	if interactor.has_method("equip_weapon"):
		# The String() constructor converts the enum value (e.g., WeaponType.PISTOL)
		# to its string name ("PISTOL"). We make it lowercased for consistency.
		interactor.equip_weapon(String(WeaponType.keys()[weapon_to_give]).to_upper())
		
		# The item has been collected, so remove it from the world.
		queue_free()
