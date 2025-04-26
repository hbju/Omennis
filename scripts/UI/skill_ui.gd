extends Control
class_name SkillUI

@onready var skill_tree = $bg/skill_tree_container/skill_tree
@onready var title = $UI_title/title
@onready var class_icon = $UI_title/class_icon
@onready var close_button = $UI_title/close_button

const SkillTooltipScene: PackedScene = preload("res://scenes/skill_tooltip.tscn")
var skill_tooltip_instance: PanelContainer


func _ready():
	if SkillTooltipScene:
		skill_tooltip_instance = SkillTooltipScene.instantiate()
		add_child(skill_tooltip_instance) 
		skill_tooltip_instance.hide()
	else:
		printerr("SkillTree: Skill Tooltip Scene not assigned!")

	close_button.pressed.connect(_on_close_button_pressed)
	skill_tree.skill_tooltip_needed.connect(_on_skill_tooltip_needed)
	skill_tree.skill_tooltip_not_needed.connect(_on_skill_tooltip_not_needed)
	
	await get_tree().process_frame


func update_ui(party_member: PartyMember) : 
	title.text = party_member.get_char_class()
	class_icon.texture = load("res://assets/ui/classes_icons/" + party_member.get_char_class() + ".png")
	skill_tree.update_ui(party_member)
	$bg/skill_tree_container.scroll_vertical = 1331


func _on_close_button_pressed() : 
	visible = false
	
func _on_skill_tooltip_needed(hovered_node: SkillNode, skill_data: Skill) -> void:
	if skill_tooltip_instance and is_instance_valid(hovered_node): 	
		skill_tooltip_instance.update_content(skill_data)

		print("new size : ", skill_tooltip_instance.size)
		print("new min size : ", skill_tooltip_instance.get_combined_minimum_size())


		# Get necessary info for positioning
		var tooltip_size = skill_tooltip_instance.size 

		var viewport_rect = get_viewport_rect()
		var offset = Vector2(10, 0) 

		var target_pos = hovered_node.global_position + Vector2(hovered_node.size.x, 0) + offset
		print("hovered_node: ", hovered_node.global_position)

		if target_pos.x + tooltip_size.x > viewport_rect.size.x:
			target_pos.x = hovered_node.global_position.x - tooltip_size.x - offset.x

		if target_pos.y + tooltip_size.y > viewport_rect.size.y:
			target_pos.y = viewport_rect.size.y - tooltip_size.y # Stick to viewport bottom

		if target_pos.y < 0:
			target_pos.y = 0 

		if target_pos.x < 0:
			target_pos.x = 0 

		skill_tooltip_instance.global_position = target_pos
		skill_tooltip_instance.show()

func _on_skill_tooltip_not_needed():
	if skill_tooltip_instance:
		skill_tooltip_instance.hide()