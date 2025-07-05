class_name WeaponItem
extends BaseItem

enum EquipSlot { WEAPON } 

@export_group("Weapon Properties")
@export var equip_slot: EquipSlot = EquipSlot.WEAPON

@export_group("Weapon Stats")
@export var damage_bonus: float = 0.0
@export_range(0.0, 1.0, 0.01) var crit_chance_bonus: float = 0.0

@export var granted_skill: Skill = null