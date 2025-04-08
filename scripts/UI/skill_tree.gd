extends MarginContainer
class_name SkillTree

@export var debugging: bool = false

var skills: Array[SkillNode]

var party_member: PartyMember


func _ready() :
	_get_skills($background, skills)
	for skill in skills : 
		skill.skill_unlocked.connect(_on_skill_unlocked)

	if debugging:
		party_member = PartyMember.new("Hbju", Character.CLASSES.Warrior, 1, 5, PartyMember.SEX.Male)
		party_member.skill_points = 10
		update_ui(party_member)


func update_ui(new_member: PartyMember) : 
	party_member = new_member
	var remaining_points = party_member.skill_points

	var warrior_skills = [Charge.new(), DefensiveStance.new(), ShieldBash.new(), GuardiansAura.new(), HolyStrike.new(), DivineShield.new(), ZealousCharge.new(), Inquisition.new(), Frenzy.new(), RageSlam.new(), WarCry.new(), Whirlwind.new(), BloodFury.new(), RagingBlow.new()]
	var mage_skills = [Firespark.new(), Sprint.new(), Charge.new(), Firespark.new(), Sprint.new(), Charge.new(), Firespark.new(), Sprint.new(), Charge.new(),Firespark.new(), Sprint.new(), Charge.new(), Firespark.new(), Sprint.new()	]
	var rogue_skills = [Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new(), Firespark.new(),Sprint.new(), Charge.new()]

	var curr_skills = warrior_skills if party_member.get_char_class() == "Warrior" else mage_skills if party_member.get_char_class() == "Mage" else rogue_skills

	for skill in skills:
		skill.update_node(party_member.spent_skill_points, curr_skills.pop_front(), remaining_points, party_member)


func _on_skill_unlocked(skill: Skill) :
	party_member.skill_list.append(skill)
	party_member.spend_skill_point()
	update_ui(party_member)

func _get_skills(node: Node, result : Array[SkillNode]) -> void:
	if node is SkillNode :
		result.append(node)
	for child in node.get_children():
		_get_skills(child, result)

