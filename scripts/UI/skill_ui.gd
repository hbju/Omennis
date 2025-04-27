extends Control
class_name SkillUI


@export var debugging: bool = false

@onready var skill_tree: SkillTree = $bg/skill_tree_container/skill_tree
@onready var title = $bg/UI_title/title
@onready var class_icon = $bg/UI_title/class_icon
@onready var close_button = $bg/UI_title/close_button

@onready var equipped_slot_1: TextureButton = $bg/equipped_skills_container/equipped_skill_1 # Adjust path
@onready var equipped_slot_2: TextureButton = $bg/equipped_skills_container/equipped_skill_2
@onready var equipped_slot_3: TextureButton = $bg/equipped_skills_container/equipped_skill_3

@onready var icon_slot_1: TextureRect = $bg/equipped_skills_container/equipped_skill_1/skill_icon
@onready var icon_slot_2: TextureRect = $bg/equipped_skills_container/equipped_skill_2/skill_icon
@onready var icon_slot_3: TextureRect = $bg/equipped_skills_container/equipped_skill_3/skill_icon

var curr_party_member: PartyMember = null
var pending_selection = null # Can hold either slot_index (int) or skill (Skill)

enum SelectionMode { NONE, SELECTING_SKILL_FOR_SLOT, SELECTING_SLOT_FOR_SKILL }
var current_selection_mode = SelectionMode.NONE

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

	equipped_slot_1.pressed.connect(_on_equipped_slot_pressed.bind(0))
	equipped_slot_2.pressed.connect(_on_equipped_slot_pressed.bind(1))
	equipped_slot_3.pressed.connect(_on_equipped_slot_pressed.bind(2))

	equipped_slot_1.mouse_entered.connect(_on_slot_hovered.bind(0))
	equipped_slot_2.mouse_entered.connect(_on_slot_hovered.bind(1))
	equipped_slot_3.mouse_entered.connect(_on_slot_hovered.bind(2))
	equipped_slot_1.mouse_exited.connect(_on_skill_tooltip_not_needed)
	equipped_slot_2.mouse_exited.connect(_on_skill_tooltip_not_needed)
	equipped_slot_3.mouse_exited.connect(_on_skill_tooltip_not_needed)

	skill_tree.unlocked_skill_pressed.connect(_on_skill_selected_from_tree)
	
	await get_tree().process_frame

	if debugging:
		curr_party_member = PartyMember.new("DebugWarrior", Character.CLASSES.Mage, 1, 5, PartyMember.SEX.Male)
		curr_party_member.skill_points = 10
		update_ui(curr_party_member)


func update_ui(party_member: PartyMember) : 
	self.curr_party_member = party_member

	title.text = party_member.get_char_class()
	class_icon.texture = load("res://assets/ui/classes_icons/" + party_member.get_char_class() + ".png")

	skill_tree.update_ui(party_member)

	_update_equipped_slots()

	# Reset selection state
	_cancel_selection()

	$bg/skill_tree_container.scroll_vertical = 1431


func _on_close_button_pressed() : 
	_cancel_selection()
	visible = false

func _on_slot_hovered(slot_index: int):
	if not curr_party_member or curr_party_member.skill_list.size() <= slot_index : return
	if current_selection_mode == SelectionMode.NONE:
		var button = [equipped_slot_1, equipped_slot_2, equipped_slot_3][slot_index]
		var skill_data = curr_party_member.skill_list[slot_index]
		if skill_data:
			_on_skill_tooltip_needed(button, skill_data)
	
func _on_skill_tooltip_needed(hovered_node: TextureButton, skill_data: Skill) -> void:
	if skill_tooltip_instance and is_instance_valid(hovered_node): 	
		skill_tooltip_instance.update_content(skill_data)

		# Get necessary info for positioning
		var tooltip_size = skill_tooltip_instance.size 

		var viewport_rect = get_viewport_rect()
		var offset = Vector2(10, 0) 

		var target_pos = hovered_node.global_position + Vector2(hovered_node.size.x, 0) + offset

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

func _update_equipped_slots():
	if not curr_party_member: return

	var equipped_skills = curr_party_member.skill_list
	var slots = [icon_slot_1, icon_slot_2, icon_slot_3]

	for i in range(3):
		if i < equipped_skills.size() and equipped_skills[i]:
			slots[i].texture = equipped_skills[i].get_skill_icon()
			slots[i].show()
		else:
			slots[i].texture = null
			slots[i].hide()



func _on_equipped_slot_pressed(slot_index: int):
	match current_selection_mode:
		SelectionMode.NONE:
			# Start selecting a skill FOR this slot
			pending_selection = slot_index
			current_selection_mode = SelectionMode.SELECTING_SKILL_FOR_SLOT
			skill_tree.set_highlight_mode(SelectionMode.SELECTING_SKILL_FOR_SLOT, curr_party_member.skill_list)
			_update_slot_highlights()

		SelectionMode.SELECTING_SKILL_FOR_SLOT:
			if pending_selection == slot_index:
				_cancel_selection()
			else:
				pending_selection = slot_index
				_update_slot_highlights() # Update highlights

		SelectionMode.SELECTING_SLOT_FOR_SKILL:
			if pending_selection is Skill:
				_equip_skill(pending_selection, slot_index)
			else:
				_cancel_selection()




func _on_skill_selected_from_tree(selected_skill: Skill):
	match current_selection_mode:
		SelectionMode.NONE:
			# Start selecting a slot FOR this skill
			pending_selection = selected_skill
			current_selection_mode = SelectionMode.SELECTING_SLOT_FOR_SKILL
			skill_tree.set_highlight_mode(SelectionMode.SELECTING_SLOT_FOR_SKILL, curr_party_member.skill_list, selected_skill) # Highlight selected skill node
			_update_slot_highlights() # Highlight available slots

		SelectionMode.SELECTING_SLOT_FOR_SKILL:
			# Selecting the same skill again cancels
			if pending_selection == selected_skill:
				_cancel_selection()
			else:
				# Selecting a different skill switches the pending skill
				pending_selection = selected_skill
				skill_tree.set_highlight_mode(SelectionMode.SELECTING_SLOT_FOR_SKILL, [], selected_skill) # Update tree highlight

		SelectionMode.SELECTING_SKILL_FOR_SLOT:
			# A slot is pending, equip THIS skill to that slot
			if pending_selection is int:
				_equip_skill(selected_skill, pending_selection)
			else:
				printerr("Error: Pending selection was not an int when selecting skill.")
				_cancel_selection()


func _equip_skill(skill_to_equip: Skill, target_slot_index: int):
	if not curr_party_member: return

	var current_equipped = curr_party_member.skill_list

	# Check if the skill is already in another slot and handle swap/removal
	var existing_index = current_equipped.find(skill_to_equip)
	if existing_index != -1 and existing_index != target_slot_index:
		current_equipped[existing_index] = null

	# Ensure array is big enough
	while current_equipped.size() <= target_slot_index:
		current_equipped.append(null)

	# Place the new skill
	current_equipped[target_slot_index] = skill_to_equip

	# Clean up trailing nulls (optional)
	while not current_equipped.is_empty() and current_equipped.back() == null:
		current_equipped.pop_back()

	_cancel_selection() # Clear pending state and exit selection mode
	_update_equipped_slots() # Refresh display


func _cancel_selection():
	pending_selection = null
	current_selection_mode = SelectionMode.NONE
	skill_tree.set_highlight_mode(SelectionMode.NONE) # Tell tree to clear highlights
	_update_slot_highlights() # Clear slot highlights


func _update_slot_highlights():
	var slots = [equipped_slot_1, equipped_slot_2, equipped_slot_3]
	for i in range(slots.size()):
		var button = slots[i]
		match current_selection_mode:
			SelectionMode.NONE:
				button.modulate = Color.WHITE # Normal state
			SelectionMode.SELECTING_SKILL_FOR_SLOT:
				# Highlight the slot that is pending
				if pending_selection == i:
					button.modulate = Color.GOLD # Highlight pending slot
				else:
					button.modulate = Color.WHITE
			SelectionMode.SELECTING_SLOT_FOR_SKILL:
				if curr_party_member.skill_list.size() <= i or not curr_party_member.skill_list[i] :
					button.modulate = Color.GOLD # Highlight the slot with the pending skill
				else:
					button.modulate = Color.LIGHT_BLUE