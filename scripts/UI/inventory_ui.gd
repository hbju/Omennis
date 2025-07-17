# inventory_ui.gd
extends PanelContainer

@onready var equipment_weapon_slot: ItemSlot = $equipment_vbox/weapon_slot # Adjust path
@onready var equipment_armor_slot: ItemSlot = $equipment_vbox/armor_slot
@onready var equipment_accessory_slot: ItemSlot = $equipment_vbox/accessory_slot
@onready var inventory_grid: GridContainer = $inventory_grid

const ItemTooltipScene: PackedScene = preload("res://scenes/item_tooltip.tscn")
var item_tooltip: Control = null

# --- State Variables ---
var current_character: PartyMember = null

func _ready():
	# Initialize the item tooltip
	if ItemTooltipScene :
		item_tooltip = ItemTooltipScene.instantiate()
		add_child(item_tooltip)
		item_tooltip.top_level = true  # Ensure it appears above other UI elements
		item_tooltip.hide()  # Start hidden
	
	# Ensure the inventory is empty on start
	show_inventory(null)

func show_inventory(character: PartyMember):
	if not character:
		hide()
		return
	
	print("Showing inventory for character: ", character.character_name)
	current_character = character
	populate_equipment_slots()
	populate_inventory_grid()


func populate_equipment_slots():
	if not current_character: return
	
	equipment_weapon_slot.item_data = current_character.equipment_slots.weapon
	if not equipment_weapon_slot.item_data:
		print("No weapon equipped for ", current_character.character_name)
		equipment_weapon_slot.background.texture = load("res://assets/ui/items/weapon_bg.png") as Texture
		equipment_weapon_slot.background.show()
	equipment_armor_slot.item_data = current_character.equipment_slots.armor
	if not equipment_armor_slot.item_data:
		print("No armor equipped for ", current_character.character_name)
		equipment_armor_slot.background.texture = load("res://assets/ui/items/armor_bg.png") as Texture
		equipment_armor_slot.background.show()
	equipment_accessory_slot.item_data = current_character.equipment_slots.accessory
	if not equipment_accessory_slot.item_data:
		print("No accessory equipped for ", current_character.character_name)
		equipment_accessory_slot.background.texture = load("res://assets/ui/items/accessory_bg.png") as Texture
		equipment_accessory_slot.background.show()

	for slot in [equipment_weapon_slot, equipment_armor_slot, equipment_accessory_slot]:
		if not slot.mouse_entered.is_connected(_on_slot_hover.bind(slot)):
			slot.mouse_entered.connect(_on_slot_hover.bind(slot))
		if not slot.mouse_exited.is_connected(item_tooltip.hide):
			slot.mouse_exited.connect(item_tooltip.hide)

func populate_inventory_grid():
	# Clear old grid
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Add an ItemSlot for each item in the shared inventory
	for item in GameState.party_inventory:
		var slot = preload("res://scenes/item_slot.tscn").instantiate()
		inventory_grid.add_child(slot)
		slot.item_data = item
		slot.mouse_entered.connect(_on_slot_hover.bind(slot))
		slot.mouse_exited.connect(item_tooltip.hide)
		if item.item_lvl > current_character.character_level:
			slot.background.modulate = Color.RED  # Highlight items above character level
			slot.icon.modulate = Color.RED
		else:
			slot.background.modulate = Color.WHITE  # Reset color for valid items
			slot.icon.modulate = Color.WHITE  # Reset color for valid items

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Find which slot is at the mouse position
	var source_slot = find_slot_at_position(get_global_mouse_position())
	print("Source slot found: ", source_slot)
	if source_slot and source_slot.item_data:
		# Create a payload with all the info we need
		var payload = {
			"type": "item_drag",
			"item": source_slot.item_data,
			"source_slot_node": source_slot
		}
		
		# Create a preview image for the drag
		var preview = TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture = source_slot.item_data.icon
		preview.size = Vector2(100, 100)
		set_drag_preview(preview)
		
		return payload
	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "item_drag":
		if current_character.character_level < data.item.item_lvl:
			return false  # Prevent dropping items above character level

		var target_slot = find_slot_at_position(get_global_mouse_position())
		print("Target slot found: ", target_slot)
		if target_slot:
			var item_being_dragged = data.item as BaseItem
			# --- The Core Validation Logic ---
			if target_slot.name == "weapon_slot" and item_being_dragged is WeaponItem:
				return true
			if target_slot.name == "armor_slot" and item_being_dragged is EquipmentItem and item_being_dragged.equip_slot == EquipmentItem.EquipSlot.ARMOR:
				return true
			if target_slot.name == "accessory_slot" and item_being_dragged is EquipmentItem and item_being_dragged.equip_slot == EquipmentItem.EquipSlot.ACCESSORY:
				return true
			# If the target is in the main inventory grid, it's always a valid drop.
			if target_slot.get_parent() == inventory_grid:
				return true
	return false

# This is called when the drop is completed.
func _drop_data(_at_position: Vector2, data: Variant):
	var target_slot = find_slot_at_position(get_global_mouse_position())
	var source_slot = data.source_slot_node as ItemSlot
	var item = data.item as BaseItem

	if not target_slot: return

	# Case 1: Dragging from Equipment to Inventory
	if source_slot.get_parent() != inventory_grid and target_slot.get_parent() == inventory_grid:
		current_character.unequip_item(source_slot.name.to_lower().replace("slot", ""))
	
	# Case 2: Dragging from Inventory to Equipment
	elif source_slot.get_parent() == inventory_grid and target_slot.get_parent() != inventory_grid:
		current_character.equip_item(item)
		
	# Case 3: Swapping two inventory items
	elif source_slot.get_parent() == inventory_grid and target_slot.get_parent() == inventory_grid:
		var source_item = source_slot.item_data
		var target_item = target_slot.item_data

		var source_index = GameState.party_inventory.find(source_item)
		var target_index = GameState.party_inventory.find(target_item)

		GameState.party_inventory[source_index] = target_item
		GameState.party_inventory[target_index] = source_item

	# After any operation, refresh the entire UI to reflect the new state
	show_inventory(current_character)

func _on_slot_hover(slot: ItemSlot):
	# Show the item tooltip when hovering over a slot
	if slot.item_data:
		item_tooltip.update_content(slot.item_data)
		var slot_rect: Rect2 = slot.get_global_rect()
		print("Slot hovered: ", slot.name, " at position: ", slot_rect.position, " with size: ", slot_rect.size)
		var tooltip_size: Vector2 = item_tooltip.item_container.size
		print("Tooltip size: ", tooltip_size)
		var new_position = Vector2(slot_rect.position.x + slot_rect.size.x + 5, slot_rect.position.y)
		if new_position.x + slot_rect.size.x + tooltip_size.x > get_viewport().size.x:
			# If it goes off-screen, adjust to the left side
			new_position.x = slot_rect.position.x - tooltip_size.x - 5
		if new_position.y + tooltip_size.y > get_viewport().size.y:
			# If it goes off-screen vertically, adjust to the top
			new_position.y = get_viewport().size.y - tooltip_size.y - 5
		print("New tooltip position: ", new_position)
		item_tooltip.global_position = new_position

# Helper function to identify the slot under the mouse
func find_slot_at_position(mouse_pos: Vector2) -> ItemSlot:
	# Check equipment slots first
	if equipment_weapon_slot.get_global_rect().has_point(mouse_pos): return equipment_weapon_slot
	if equipment_armor_slot.get_global_rect().has_point(mouse_pos): return equipment_armor_slot
	if equipment_accessory_slot.get_global_rect().has_point(mouse_pos): return equipment_accessory_slot

	# Then check all slots in the inventory grid
	for slot in inventory_grid.get_children():
		if slot.get_global_rect().has_point(mouse_pos):
			return slot as ItemSlot
			
	return null


	
