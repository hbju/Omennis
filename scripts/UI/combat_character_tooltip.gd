class_name CombatCharacterTooltipUI
extends PanelContainer

@onready var info_label: Label = $VBoxContainer/info_label

@onready var base_skill_cooldown = $VBoxContainer/base_skill_button/skill_cooldown
@onready var base_skill_icon = $VBoxContainer/base_skill_button/skill_icon

@onready var skill_cooldowns = [
	$VBoxContainer/HBoxContainer/skill_button_1/skill_cooldown_1,
	$VBoxContainer/HBoxContainer/skill_button_2/skill_cooldown_2,
	$VBoxContainer/HBoxContainer/skill_button_3/skill_cooldown_3
]
@onready var skill_icons = [
	$VBoxContainer/HBoxContainer/skill_button_1/skill_icon_1,
	$VBoxContainer/HBoxContainer/skill_button_2/skill_icon_2,
	$VBoxContainer/HBoxContainer/skill_button_3/skill_icon_3
]
func update_content(character: CombatCharacter):
	if not character:
		hide()
		return

	info_label.text = "Name: " + character.character.character_name + "\n" + \
					"Class: " + character.character.get_char_class() + "\n" + \
					"Level: " + str(character.character.character_level) + "\n" + \
					"Base Damage: " + str(character.character.base_damage) + "\n" 

	base_skill_cooldown.text = str(character.character.base_skill.get_cooldown())
	if character.character.base_skill.get_cooldown() > 0:
		base_skill_cooldown.show()
	else:
		base_skill_cooldown.hide()
	base_skill_icon.texture = character.character.base_skill.get_skill_icon()

	for i in range(0, 3):
		if i < character.character.skill_list.size():
			var skill = character.character.skill_list[i]
			skill_cooldowns[i].text = str(skill.get_cooldown())
			if skill.get_cooldown() > 0:
				skill_cooldowns[i].show()
			else:
				skill_cooldowns[i].hide()
			skill_icons[i].texture = skill.get_skill_icon()
			skill_icons[i].show()
		else:
			skill_cooldowns[i].text = ""
			skill_icons[i].hide()

	# Adjust size after content update
	reset_size()
	await get_tree().process_frame # Wait a frame for size to update reliably
	custom_minimum_size = size

func _ready():
	hide() # Start hidden
	mouse_filter = MOUSE_FILTER_IGNORE # Tooltip shouldn't block mouse input