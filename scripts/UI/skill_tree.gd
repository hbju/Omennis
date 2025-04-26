extends MarginContainer
class_name SkillTree

@export var debugging: bool = false

var skills: Array[SkillNode]

var party_member: PartyMember

signal skill_tooltip_needed(hovered_node: SkillNode, skill_data: Skill)
signal skill_tooltip_not_needed(skill_data: Skill)

func _ready() :
	_get_skills($background, skills)
	for skill_node in skills : 
		# Check if signals are already connected if _ready can be called multiple times
		if not skill_node.skill_unlocked.is_connected(_on_skill_unlocked):
			skill_node.skill_unlocked.connect(_on_skill_unlocked)
		if not skill_node.skill_hover_entered.is_connected(_on_skill_hover_entered):
			skill_node.skill_hover_entered.connect(_on_skill_hover_entered)
		if not skill_node.skill_hover_exited.is_connected(_on_skill_hover_exited):
			skill_node.skill_hover_exited.connect(_on_skill_hover_exited)

	if debugging:
		party_member = PartyMember.new("DebugWarrior", Character.CLASSES.Warrior, 1, 5, PartyMember.SEX.Male)
		party_member.skill_points = 10
		update_ui(party_member)


func update_ui(new_member: PartyMember) : 
	party_member = new_member
	var remaining_points = party_member.skill_points

	var warrior_skills = [Charge.new(), DefensiveStance.new(), ShieldBash.new(), GuardiansAura.new(), HolyStrike.new(), DivineShield.new(), ZealousCharge.new(), Inquisition.new(), Frenzy.new(), RageSlam.new(), WarCry.new(), Whirlwind.new(), BloodFury.new(), RagingBlow.new()]
	var mage_skills = [FiresparkMage.new(), ArcaneShield.new(), Frostbolt.new(), Thunderstrike.new(), LightningStorm.new(), Meteor.new(), ArcaneSlash.new(), MoltenBlade.new(), DarkPact.new(), DrainLife.new(), BoneArmor.new(), SoulHarvest.new(), DeathCoil.new(), Decay.new()]
	var rogue_skills = [Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new()]

	var curr_skills = warrior_skills if party_member.get_char_class() == "Warrior" else mage_skills if party_member.get_char_class() == "Mage" else rogue_skills

	for i in range(min(skills.size(), curr_skills.size())):
		var skill_node = skills[i]
		var skill_data = curr_skills[i] 
		skill_node.update_node(party_member.spent_skill_points, skill_data, remaining_points, party_member)


func _on_skill_unlocked(skill_data: Skill) :
	if party_member and party_member.skill_points > 0: 
		if not skill_data in party_member.skill_list:
			party_member.skill_list.append(skill_data)
			party_member.spend_skill_point()
			update_ui(party_member) 
			_on_skill_hover_exited()

func _get_skills(node: Node, result : Array[SkillNode]) -> void:
	if node is SkillNode :
		result.append(node)

	for child in node.get_children():
		_get_skills(child, result)

func _on_skill_hover_entered(hovered_node: SkillNode, skill_data: Skill):	
	skill_tooltip_needed.emit(hovered_node, skill_data)


func _on_skill_hover_exited():
	skill_tooltip_not_needed.emit()
