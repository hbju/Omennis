class_name BaseItem
extends Resource

# Enum for item rarity, useful for color-coding, sorting, etc.
enum ItemTier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export_group("Core Properties")
@export var item_lvl : int = 0
@export var item_name: String = "New Item"
@export_multiline var description: String = "A basic item description."
@export var icon: Texture
@export var tier: ItemTier = ItemTier.COMMON
@export var value: int = 10 # For buying/selling later