extends TextureRect
class_name SkillBarUI

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



func update_ui(character: Character) : 
	self.skill_list = character.skill_list

	for i in range(0, 3) : 
		if i < character.skill_list.size() : 
			var skill = character.skill_list[i]
			match i : 
				0 : 
					button_skill_1.modulate = Color(1, 1, 1)
					button_skill_1.show()
					button_skill_1.disabled = false
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
					button_skill_2.disabled = false
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
					button_skill_3.disabled = false
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


