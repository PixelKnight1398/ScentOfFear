class_name WeaponData
extends ItemData

## Defines the type of ammo the weapon uses.
#enum AmmoType { PISTOL, RIFLE, SHOTGUN, ENERGY }

# --- WEAPON STATISTICS ---

@export var damage: float = 10.0
@export var magazine_size: int = 7
@export var fire_rate: float = 0.5 # Time in seconds between shots
#@export var ammo_type: AmmoType = AmmoType.PISTOL
