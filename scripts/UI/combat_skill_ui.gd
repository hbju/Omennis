extends TextureRect
class_name SkillBarUI

const skill_tooltip_scene: PackedScene = preload("res://scenes/skill_tooltip.tscn")
var skill_tooltip_instance: PanelContainer

@onready var button_skill_1 = $skill_button_1
@onready var cooldown_skill_1 = $skill_button_1/skill_cooldown_1
@onready var icon_skill_1 = $skill_button_1/skill_icon_1

@onready var button_skill_2 = $skill_button_2
@onready var cooldown_skill_2 = $skill_button_2/skill_cooldown_2
@onready var icon_skill_2 = $skill_button_2/skill_icon_2

@onready var button_skill_3 = $skill_button_3
@onready var cooldown_skill_3 = $skill_button_3/skill_cooldown_3
@onready var icon_skill_3 = $skill_button_3/skill_icon_3

var targeting_skill: int = -1
var skill_list: Array[Skill] = []

signal choose_target(skill: Skill)

func _ready() -> void : 
	button_skill_1.pressed.connect(_choose_target.bind(0))
	button_skill_2.pressed.connect(_choose_target.bind(1))
	button_skill_3.pressed.connect(_choose_target.bind(2))

	if skill_tooltip_scene:
		skill_tooltip_instance = skill_tooltip_scene.instantiate()
		add_child(skill_tooltip_instance) 
		skill_tooltip_instance.top_level = true 
		skill_tooltip_instance.hide()
	else:
		printerr("Skill Tooltip Scene not assigned to SkillBarUI!")

	button_skill_1.mouse_entered.connect(_on_skill_button_mouse_entered.bind(0))
	button_skill_1.mouse_exited.connect(_on_skill_button_mouse_exited)
	button_skill_2.mouse_entered.connect(_on_skill_button_mouse_entered.bind(1))
	button_skill_2.mouse_exited.connect(_on_skill_button_mouse_exited)
	button_skill_3.mouse_entered.connect(_on_skill_button_mouse_entered.bind(2))
	button_skill_3.mouse_exited.connect(_on_skill_button_mouse_exited)



func update_ui(character: Character, enemy_turn: bool= false ) : 
	self.skill_list = character.skill_list

	for i in range(0, 3) : 
		if i < character.skill_list.size() : 
			var skill = character.skill_list[i]
			match i : 
				0 : 
					button_skill_1.modulate = Color(1, 1, 1)
					button_skill_1.show()
					button_skill_1.disabled = enemy_turn
					cooldown_skill_1.show()
					if skill.cooldown > 0 : 
						cooldown_skill_1.text = str(skill.get_cooldown())
					else : 
						cooldown_skill_1.text = ""
					icon_skill_1.show()
					icon_skill_1.texture = skill.get_skill_icon()
				1 : 
					button_skill_2.modulate = Color(1, 1, 1)
					button_skill_2.show()
					button_skill_2.disabled = enemy_turn
					cooldown_skill_2.show()
					if skill.cooldown > 0 : 
						cooldown_skill_2.text = str(skill.get_cooldown())
					else : 
						cooldown_skill_2.text = ""
					icon_skill_2.show()
					icon_skill_2.texture = skill.get_skill_icon()
				2 : 
					button_skill_3.modulate = Color(1, 1, 1)
					button_skill_3.show()
					button_skill_3.disabled = enemy_turn
					cooldown_skill_3.show()
					if skill.cooldown > 0 : 
						cooldown_skill_3.text = str(skill.get_cooldown())
					else : 
						cooldown_skill_3.text = ""
					icon_skill_3.show()
					icon_skill_3.texture = skill.get_skill_icon()
		else : 
			match i : 
				0 : 
					button_skill_1.modulate = Color(0.7, 0.7, 0.7)
					button_skill_1.disabled = true
					cooldown_skill_1.hide()
					icon_skill_1.hide()
				1 : 
					button_skill_2.modulate = Color(0.7, 0.7, 0.7)
					button_skill_2.disabled = true	
					cooldown_skill_2.hide()
					icon_skill_2.hide()
				2 : 
					button_skill_3.modulate = Color(0.7, 0.7, 0.7)
					button_skill_3.disabled = true
					cooldown_skill_3.hide()
					icon_skill_3.hide()


func _choose_target(index: int) : 
	if skill_list[index].get_cooldown() == 0 : 
		choose_target.emit(skill_list[index])


func _on_skill_button_mouse_entered(skill_index: int):
	if not skill_tooltip_instance: return # Tooltip doesn't exist
	if skill_index < 0 or skill_index >= skill_list.size(): return # Invalid index

	skill_tooltip_instance.reset_size()


	var skill: Skill = skill_list[skill_index]
	var button: TextureButton = get_node("skill_button_" + str(skill_index + 1)) # Get the specific button

	skill_tooltip_instance.update_content(skill)
	var cd_text = "CD: %d/%d" % [skill.cooldown, skill.max_cooldown]
	if skill_tooltip_instance.has_node("VBoxContainer/CooldownLabel"): # If you add a CD label
		skill_tooltip_instance.get_node("VBoxContainer/CooldownLabel").text = cd_text


	var tooltip_size = skill_tooltip_instance.size
	var viewport_rect = get_viewport_rect()
	var offset = Vector2(0, -10) # Position above the button

	# Calculate position (usually above the button)
	var target_pos = button.global_position + Vector2(button.size.x / 2 - tooltip_size.x / 2, -tooltip_size.y) + offset


	# Adjust if off-screen (simplified)
	if target_pos.x < 0: target_pos.x = 0
	if target_pos.x + tooltip_size.x > viewport_rect.size.x: target_pos.x = viewport_rect.size.x - tooltip_size.x
	if target_pos.y < 0: target_pos.y = button.global_position.y + button.size.y + offset.y # Put below if no space above

	skill_tooltip_instance.position = target_pos
	skill_tooltip_instance.show()

func _on_skill_button_mouse_exited():
	if skill_tooltip_instance:
		skill_tooltip_instance.hide()
