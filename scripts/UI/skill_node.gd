extends TextureButton
class_name SkillNode

@onready var skill_icon: TextureRect = $skill_icon

@export var previous_node: SkillNode


var skill: Skill
var curr_char: PartyMember
var remaining_points: int

var min_spent_points: int

var glowing: bool = false

var is_unlocked: Array[PartyMember] = []

signal skill_hover_entered(skill_node: Control, skill: Skill) 
signal skill_hover_exited()
signal skill_unlocked(skill: Skill)

func _ready():
	pressed.connect(_on_skillNode_pressed)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func update_node(spent_points: int, new_skill: Skill, skill_points: int, party_member: PartyMember):
	self_modulate = Color(1, 1, 1, 1)
	skill_icon.texture = new_skill.get_skill_icon()
	skill_icon.modulate = Color(1, 1, 1, 1)

	skill = new_skill
	remaining_points = skill_points
	curr_char = party_member
	if previous_node and not previous_node.is_unlocked.has(curr_char):
		disabled = true
	else:
		disabled = false


func _on_skillNode_pressed():
	if remaining_points > 0 :
		is_unlocked.append(curr_char)
		skill_unlocked.emit(skill)
		disabled = true

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

	if not disabled and not is_unlocked.has(curr_char) and remaining_points > 0:
		if glowing:
			self_modulate.b -= clamp(delta * 2, 0, 1)
			if self_modulate.b <= 0:
				glowing = false
		else:
			self_modulate.b += clamp(delta * 2, 0, 1)
			if self_modulate.b >= 1:
				glowing = true

	elif is_unlocked.has(curr_char):
		self_modulate = Color(1, 1, 1, 1)

	else :
		$skill_icon.modulate = Color(0.5, 0.5, 0.5, 1)
		self_modulate = Color(0.5, 0.5, 0.5, 1)
	
