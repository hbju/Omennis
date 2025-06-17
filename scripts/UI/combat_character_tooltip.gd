class_name CombatCharacterTooltipUI
extends PanelContainer

@onready var info_label: Label = $VBoxContainer/info_label

@onready var base_skill_button = $VBoxContainer/base_skill_button
@onready var base_skill_cooldown = $VBoxContainer/base_skill_button/skill_cooldown
@onready var base_skill_icon = $VBoxContainer/base_skill_button/skill_icon

@onready var skill_buttons = [
    $VBoxContainer/HBoxContainer/skill_button_1,
    $VBoxContainer/HBoxContainer/skill_button_2,
    $VBoxContainer/HBoxContainer/skill_button_3
]
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

signal skill_hovered(skill: Skill)
signal skill_unhovered()

var displayed_character: CombatCharacter = null

func update_content(character: CombatCharacter):
	if not character:
		print("CombatCharacterTooltipUI: update_content called with null character")
		hide()
		return

	displayed_character = character

	info_label.text = "Name: " + character.character.character_name + "\n" + \
					"Class: " + character.character.get_char_class() + "\n" + \
					"Level: " + str(character.character.character_level) + "\n" + \
					"Base Damage: " + str(character.character.base_damage) + "\n" 

	if character.character.base_skill:
		base_skill_button.show()
		base_skill_cooldown.text = str(character.character.base_skill.get_cooldown())
		if character.character.base_skill.get_cooldown() > 0:
			base_skill_cooldown.show()
		else:
			base_skill_cooldown.hide()
		base_skill_icon.texture = character.character.base_skill.get_skill_icon()
	else:
		base_skill_cooldown.text = ""
		base_skill_button.hide()
		
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
	base_skill_button.mouse_entered.connect(_on_internal_skill_hover.bind(0))
	base_skill_button.mouse_exited.connect(func (): skill_unhovered.emit())

	for i in range(0, 3):
		skill_buttons[i].mouse_entered.connect(_on_internal_skill_hover.bind(i + 1))
		skill_buttons[i].mouse_exited.connect(func (): skill_unhovered.emit())

func _on_internal_skill_hover(index: int):
	if not displayed_character:
		return

	var skill: Skill = null

	if index == 0 and displayed_character.character.base_skill:
		skill = displayed_character.character.base_skill
	elif index > 0 and index - 1 < displayed_character.character.skill_list.size():
		skill = displayed_character.character.skill_list[index - 1]

	if skill:
		skill_hovered.emit(skill)