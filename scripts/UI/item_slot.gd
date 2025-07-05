@tool
class_name ItemSlot
extends PanelContainer

@onready var icon: TextureRect = $item_icon
@onready var background: TextureRect = $item_background

@export var item_name: String = "Leather Jerkin":
	set(value):
		item_name = value
		_update_item()


# This variable holds the actual item data.
# When it's set, the slot updates its appearance.
var item_data: BaseItem:
	set(value):
		item_data = value
		if item_data:
			var size_subtract: float = custom_minimum_size.x/10.0
			background.custom_minimum_size = Vector2(custom_minimum_size.x - size_subtract, custom_minimum_size.y - size_subtract)
			icon.custom_minimum_size = Vector2(custom_minimum_size.x - size_subtract, custom_minimum_size.y - size_subtract)
			icon.texture = item_data.icon
			reset_size()
			match item_data.tier:
				BaseItem.ItemTier.COMMON:
					background.hide()
				BaseItem.ItemTier.UNCOMMON:
					background.texture = preload("res://assets/ui/items/uncommon_item_bg.png")
					background.show()
				BaseItem.ItemTier.RARE:
					background.texture = preload("res://assets/ui/items/rare_item_bg.png")
					background.show()
				BaseItem.ItemTier.EPIC:
					background.texture = preload("res://assets/ui/items/epic_item_bg.png")
					background.show()
				BaseItem.ItemTier.LEGENDARY:
					background.texture = preload("res://assets/ui/items/legendary_item_bg.png")
					background.show()
			icon.show()
		else:
			# If no item, clear the slot
			icon.texture = null
			icon.hide()

func _ready():
	# Ensure the slot is empty on start
	self.item_data = load("res://items/armor/leather_jerkin.tres") as BaseItem

func _update_item():
	if Engine.is_editor_hint():
		print("Setting item_name to: ", item_name)
		var new_item_data = load("res://items/armor/" + item_name.replace(" ", "_").to_lower() + ".tres") as BaseItem
		if new_item_data:
			self.item_data = new_item_data
		else:
			print("Item not found in path : ", "res://assets/items/armor/" + item_name.replace(" ", "_").to_lower() + ".tres")