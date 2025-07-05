class_name EquipmentItem
extends BaseItem

# Defines which slot this item can be equipped in.
enum EquipSlot { ARMOR, ACCESSORY }

@export_group("Equipment Properties")
@export var equip_slot: EquipSlot = EquipSlot.ARMOR

@export_group("Equipment Stats")
@export var health_bonus: int = 0
@export var armor_bonus: int = 0 

@export var passives: Array[Resource] = []