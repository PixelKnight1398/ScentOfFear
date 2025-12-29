class_name RangedWeaponData
extends WeaponData

## Defines the type of ammo the weapon uses.
enum WeaponType { PISTOL, RIFLE, SHOTGUN, ENERGY }
@export var weapon_type: WeaponType

@export var magazine_size: int = 7
@export var fire_rate: float = 0.5 # Time in seconds between shots

#@export var ammo_type: AmmoType = AmmoType.PISTOL
