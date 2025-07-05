# item_tooltip.gd
extends Control

@onready var item_container: PanelContainer = $item_container
@onready var name_label: Label = $item_container/VBoxContainer/name_label
@onready var description_label: Label = $item_container/VBoxContainer/description_label
@onready var stats_label: Label = $item_container/VBoxContainer/stats_label
@onready var weapon_skill: TextureRect = $item_container/VBoxContainer/weapon_skill
@onready var weapon_skill_icon: TextureRect = $item_container/VBoxContainer/weapon_skill/skill_icon
@onready var skill_tooltip: PanelContainer = $skill_tooltip

signal skill_hovered(skill: Skill)
signal skill_unhovered()

var curr_skill: Skill = null

const TIER_COLORS = {
	BaseItem.ItemTier.COMMON: Color.WHITE,
	BaseItem.ItemTier.UNCOMMON: Color.GREEN,
	BaseItem.ItemTier.RARE: Color.BLUE,
	BaseItem.ItemTier.EPIC: Color.PURPLE,
	BaseItem.ItemTier.LEGENDARY: Color.ORANGE
}

func _ready():
	# Initialize the tooltip to be hidden
	weapon_skill_icon.mouse_entered.connect(_on_skill_icon_hover)
	weapon_skill_icon.mouse_exited.connect(_on_skill_icon_exit)
	skill_tooltip.global_position = Vector2(-1000, -1000) # Start
	skill_tooltip.show()
	skill_tooltip.reset_size()
	update_content(load("res://items/weapons/assassins_blade.tres")) # Load a placeholder item to set up the UI
	hide()

func update_content(item: BaseItem):
	if not item:
		hide()
		return

	
	name_label.text = item.item_name
	name_label.modulate = TIER_COLORS.get(item.tier, Color.WHITE)
	description_label.text = "\"" + item.description + "\""
	description_label.modulate = Color.GOLD
	
	var stats_text = ""
	if item.item_lvl > 0:
		stats_text += "Item Level: %d\n" % item.item_lvl
	if item is WeaponItem:
		stats_text += "Weapon\n" 
		if item.damage_bonus > 0: stats_text += "Damage: +%d\n" % item.damage_bonus
		if item.crit_chance_bonus > 0: stats_text += "Crit Chance: +%d%%\n" % (item.crit_chance_bonus * 100)
		if item.granted_skill: 
			curr_skill = item.granted_skill
			weapon_skill_icon.texture = item.granted_skill.get_skill_icon()
			weapon_skill.visible = true
			stats_text += "Skill: %s\n" % item.granted_skill.get_skill_name()
		else:
			curr_skill = null
			weapon_skill.visible = false
	
	elif item is EquipmentItem:
		stats_text += "Armor\n"
		if item.health_bonus > 0: stats_text += "Max Health: +%d\n" % item.health_bonus
		if item.armor_bonus > 0: stats_text += "Armor: +%d\n" % item.armor_bonus
		weapon_skill.visible = false
		curr_skill = null
	
	stats_label.text = stats_text
	reset_size()
	await get_tree().process_frame
	show()

func _on_skill_icon_hover():
	if curr_skill and not skill_tooltip.is_visible():
		skill_tooltip.update_content(curr_skill)

		## position the skill tooltip on the side of the item tooltip
		var item_rect: Rect2 = item_container.get_global_rect()
		var skill_rect: Rect2 = skill_tooltip.get_global_rect()
		var new_position = Vector2(item_rect.position.x + item_rect.size.x + 5, item_rect.position.y + (item_rect.size.y - skill_rect.size.y))
		if new_position.x + skill_rect.size.x > get_viewport().size.x:
			# If it goes off-screen, adjust to the left side
			new_position.x = item_rect.position.x - skill_rect.size.x - 5
		print("Item Rect: ", item_rect, " Skill Rect: ", skill_rect, " New Position: ", new_position)
		skill_tooltip.global_position = new_position
		print("Skill Tooltip Position: ", skill_tooltip.global_position)
		skill_tooltip.show()

		skill_hovered.emit(curr_skill)

func _on_skill_icon_exit():
	skill_tooltip.hide()
	skill_unhovered.emit()
