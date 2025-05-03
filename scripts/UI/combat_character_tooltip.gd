class_name CombatCharacterTooltipUI
extends PanelContainer

@onready var info_label: Label = $VBoxContainer/info_label
@onready var skill1: TextureButton = $VBoxContainer/HBoxContainer/skill_button_1
@onready var skill1_cooldown: Label = $VBoxContainer/HBoxContainer/skill_button_1/skill_cooldown_1
@onready var skill1_icon: TextureRect = $VBoxContainer/HBoxContainer/skill_button_1/skill_icon_1
@onready var skill2: TextureButton = $VBoxContainer/HBoxContainer/skill_button_2
@onready var skill2_cooldown: Label = $VBoxContainer/HBoxContainer/skill_button_2/skill_cooldown_2
@onready var skill2_icon: TextureRect = $VBoxContainer/HBoxContainer/skill_button_2/skill_icon_2
@onready var skill3: TextureButton = $VBoxContainer/HBoxContainer/skill_button_3
@onready var skill3_cooldown: Label = $VBoxContainer/HBoxContainer/skill_button_3/skill_cooldown_3
@onready var skill3_icon: TextureRect = $VBoxContainer/HBoxContainer/skill_button_3/skill_icon_3

func update_content(character: CombatCharacter):
	if not character:
		hide()
		return

	info_label.text = "Name: " + character.character.character_name + "\n" + \
					"Class: " + character.character.get_char_class() + "\n" + \
					"Level: " + str(character.character.character_level) + "\n"

	for i in range(0, 3):
		if i < character.character.skill_list.size():
			var skill = character.character.skill_list[i]
			match i:
				0:
					skill1.show()
					skill1_cooldown.text = str(skill.get_cooldown()) if skill.get_cooldown() > 0 else ""
					skill1_icon.texture = skill.get_skill_icon()
				1:
					skill2.show()
					skill2_cooldown.text = str(skill.get_cooldown()) if skill.get_cooldown() > 0 else ""
					skill2_icon.texture = skill.get_skill_icon()
				2:
					skill3.show()
					skill3_cooldown.text = str(skill.get_cooldown()) if skill.get_cooldown() > 0 else ""
					skill3_icon.texture = skill.get_skill_icon()
		else:
			match i:
				0:
					skill1.hide()
				1:
					skill2.hide()
				2:
					skill3.hide()

	# Adjust size after content update
	reset_size()
	await get_tree().process_frame # Wait a frame for size to update reliably
	custom_minimum_size = size

func _ready():
	hide() # Start hidden
	mouse_filter = MOUSE_FILTER_IGNORE # Tooltip shouldn't block mouse input