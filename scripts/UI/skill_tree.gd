extends MarginContainer
class_name SkillTree


var skills: Array[SkillNode]

var party_member: PartyMember

enum HighlightMode { NONE, HIGHLIGHT_SELECTABLE_FOR_SLOT, HIGHLIGHT_PENDING_SKILL }
var current_highlight_mode = HighlightMode.NONE
var currently_equipped_skills: Array[Skill] = []
var pending_skill_selection: Skill = null

signal unlocked_skill_pressed(skill: Skill)
signal skill_tooltip_needed(hovered_node: SkillNode, skill: Skill)
signal skill_tooltip_not_needed(skill: Skill)
signal skill_unlocked(skill: Skill)

func _ready() :
	_get_skills($background, skills)

	for skill_node in skills : 
		# Check if signals are already connected if _ready can be called multiple times
		skill_node.skill_hover_entered.connect(_on_skill_hover_entered)
		skill_node.skill_hover_exited.connect(_on_skill_hover_exited)
		skill_node.pressed.connect(_on_skill_node_activated.bind(skill_node))


func update_ui(new_member: PartyMember) : 
	party_member = new_member

	var warrior_skills: Array[Skill] = [DefensiveStance.new(), Charge.new(), ShieldBash.new(), GuardiansAura.new(), HolyStrike.new(), DivineShield.new(), ZealousCharge.new(), Inquisition.new(), Frenzy.new(), RageSlam.new(), WarCry.new(), Whirlwind.new(), BloodFury.new(), RagingBlow.new()]
	var mage_skills: Array[Skill] = [Blink.new(), ArcaneShield.new(), Frostbolt.new(), Thunderstrike.new(), LightningStorm.new(), Meteor.new(), ArcaneSlash.new(), MoltenBlade.new(), DarkPact.new(), DrainLife.new(), BoneArmor.new(), SoulHarvest.new(), DeathCoil.new(), Decay.new()]
	var rogue_skills: Array[Skill] = [Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new()]

	var background: ColorRect = $background
	var curr_skills: Array[Skill] = []
	match party_member.get_char_class():
		"Warrior":
			background.color = Color(0x81220eff)
			curr_skills = warrior_skills
		"Mage":
			background.color = Color(0x08748bff)
			curr_skills = mage_skills
		"Rogue":
			background.color = Color(0x4f4f4fff)
			curr_skills = rogue_skills

	for i in range(min(skills.size(), curr_skills.size())):
		var skill_node = skills[i]
		var skill_data = curr_skills[i] 
		skill_node.update_node(skill_data, party_member)

func set_highlight_mode(mode, equipped_skills: Array[Skill] = [], pending_skill: Skill = null):
	match mode:
		SkillUI.SelectionMode.NONE:
			current_highlight_mode = HighlightMode.NONE
		SkillUI.SelectionMode.SELECTING_SKILL_FOR_SLOT:
			current_highlight_mode = HighlightMode.HIGHLIGHT_SELECTABLE_FOR_SLOT
		SkillUI.SelectionMode.SELECTING_SLOT_FOR_SKILL:
			current_highlight_mode = HighlightMode.HIGHLIGHT_PENDING_SKILL

	currently_equipped_skills = equipped_skills
	pending_skill_selection = pending_skill # Store the skill to highlight
	_update_node_visuals()

# Helper function to update visuals based on mode
func _update_node_visuals():
	for skill_node in skills:
		skill_node.update_visual_state(current_highlight_mode, currently_equipped_skills, pending_skill_selection)


func _get_skills(node: Node, result : Array[SkillNode]) -> void:
	if node is SkillNode :
		result.append(node)

	for child in node.get_children():
		_get_skills(child, result)



func _on_skill_hover_entered(hovered_node: SkillNode, skill_data: Skill):	
	skill_tooltip_needed.emit(hovered_node, skill_data)




func _on_skill_hover_exited():
	skill_tooltip_not_needed.emit()



func _on_skill_node_activated(skill_node: SkillNode):
	var skill = skill_node.skill
	if not skill: return

	match current_highlight_mode:
		HighlightMode.NONE:
			if not skill_node.is_unlocked.has(party_member) and party_member.skill_points > 0:
				skill_node.is_unlocked.append(party_member)
				party_member.spend_skill_point()
				skill_unlocked.emit(skill)
				AudioManager.play_sfx(AudioManager.UI_SKILL_UNLOCK)
				update_ui(party_member) 
				_on_skill_hover_exited()
			elif skill_node.is_unlocked.has(party_member):
				unlocked_skill_pressed.emit(skill)
				AudioManager.play_sfx(AudioManager.UI_BUTTON_CLICK)

		HighlightMode.HIGHLIGHT_SELECTABLE_FOR_SLOT, HighlightMode.HIGHLIGHT_PENDING_SKILL:
			if skill_node.is_unlocked.has(party_member):
				unlocked_skill_pressed.emit(skill)
				AudioManager.play_sfx(AudioManager.UI_BUTTON_CLICK)
