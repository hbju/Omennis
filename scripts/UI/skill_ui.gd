extends Control
class_name SkillUI

@onready var skill_tree = $bg/skill_tree_container/skill_tree
@onready var title = $UI_title/title
@onready var class_icon = $UI_title/class_icon
@onready var close_button = $UI_title/close_button

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)


func update_ui(party_member: PartyMember) : 
	title.text = party_member.get_char_class()
	class_icon.texture = load("res://assets/ui/classes_icons/" + party_member.get_char_class() + ".png")
	skill_tree.update_ui(party_member)
	$bg/skill_tree_container.scroll_vertical = 1331


func _on_close_button_pressed() : 
	visible = false
	
