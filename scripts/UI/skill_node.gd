extends TextureButton
class_name SkillNode

@onready var skill_icon: TextureRect = $skill_icon

@export var previous_node: SkillNode


var skill: Skill
var curr_char: PartyMember

var highlight_mode: SkillTree.HighlightMode = SkillTree.HighlightMode.NONE
var glowing: bool = false

var is_unlocked: Array[PartyMember] = []

signal skill_hover_entered(skill_node: Control, skill: Skill) 
signal skill_hover_exited()
signal skill_selected_for_slot(skill: Skill)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func update_node(new_skill: Skill, party_member: PartyMember):
	self_modulate = Color(1, 1, 1, 1)
	skill_icon.texture = new_skill.get_skill_icon()
	skill_icon.modulate = Color(1, 1, 1, 1)

	skill = new_skill
	curr_char = party_member

	if party_member.unlocked_skills.has(skill.get_skill_name()):
		is_unlocked.append(party_member)
	else:
		is_unlocked.erase(party_member)

	if previous_node and not previous_node.is_unlocked.has(curr_char):
		disabled = true
	else:
		disabled = false

func update_visual_state(new_highlight_mode, equipped_skills: Array[Skill], pending_skill: Skill):
	if not curr_char: return

	var base_modulate = Color.WHITE
	var icon_modulate = Color.WHITE
	var is_unlocked_by_current = is_unlocked.has(curr_char)
	var can_unlock = curr_char.skill_points > 0 and \
					 (not previous_node or previous_node.is_unlocked.has(curr_char))

	match new_highlight_mode:
		SkillTree.HighlightMode.NONE:
			if is_unlocked_by_current or can_unlock:
				disabled = false 
			else : 
				disabled = true

		SkillTree.HighlightMode.HIGHLIGHT_SELECTABLE_FOR_SLOT:
			if is_unlocked_by_current:
				disabled = false # Can be clicked
				if skill in equipped_skills:
					base_modulate = Color.DARK_GRAY # Dim if already equipped
					icon_modulate = Color(0.6, 0.6, 0.6)
				else:
					base_modulate = Color.GOLD # Highlight selectable
					icon_modulate = Color.GOLD
			else: # Not unlocked
				disabled = true
				base_modulate = Color(0.5, 0.5, 0.5) # Dim non-selectable
				icon_modulate = Color(0.5, 0.5, 0.5)

		SkillTree.HighlightMode.HIGHLIGHT_PENDING_SKILL:
			disabled = true
			if is_unlocked_by_current and skill == pending_skill:
				base_modulate = Color.GOLD # Highlight the pending skill
				icon_modulate = Color.GOLD
				disabled = false
			elif is_unlocked_by_current:
				base_modulate = Color(0.6, 0.6, 0.6) # Dim other unlocked
				icon_modulate = Color(0.6, 0.6, 0.6)
			else: # Not unlocked
				base_modulate = Color(0.4, 0.4, 0.4)
				icon_modulate = Color(0.4, 0.4, 0.4)

	self_modulate = base_modulate
	skill_icon.modulate = icon_modulate
	highlight_mode = new_highlight_mode




func _on_mouse_entered():
	# Only show hover info if the skill has data
	if skill:
		skill_hover_entered.emit(self, skill)

func _on_mouse_exited():
	# Always emit exit signal to ensure tooltip hides
	skill_hover_exited.emit()	

func _process(delta):
	if not curr_char:
		return

	if (highlight_mode == SkillTree.HighlightMode.NONE):
		if not disabled and not is_unlocked.has(curr_char) and curr_char.skill_points > 0:
			if glowing:
				self_modulate.b -= clamp(delta * 2, 0, 1)
				skill_icon.modulate = self_modulate
				if self_modulate.b <= 0:
					glowing = false
			else:
				self_modulate.b += clamp(delta * 2, 0, 1)
				skill_icon.modulate = self_modulate
				if self_modulate.b >= 1:
					glowing = true

		elif is_unlocked.has(curr_char):
			self_modulate = Color(1, 1, 1, 1)

		else :
			$skill_icon.modulate = Color(0.5, 0.5, 0.5, 1)
			self_modulate = Color(0.5, 0.5, 0.5, 1)
	
