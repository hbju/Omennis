extends MarginContainer
class_name SkillTree


@onready var skill1: SkillNode = $background/skill_node1
@onready var skill2: SkillNode = $background/skill_node1/skill_node2
@onready var skill3: SkillNode = $background/skill_node1/skill_node3
@onready var skill_points_label: Label = $background/skill_points

var party_member: PartyMember


func _ready() :
	skill1.skill_unlocked.connect(_on_skill_unlocked)
	skill1.min_spent_points = 0
	skill2.skill_unlocked.connect(_on_skill_unlocked)
	skill2.min_spent_points = 1
	skill3.skill_unlocked.connect(_on_skill_unlocked)
	skill3.min_spent_points = 1

func update_ui(new_member: PartyMember) : 
	party_member = new_member
	var remaining_points = party_member.skill_points
	skill_points_label.text = str(remaining_points) + " skill points remaining"

	var warrior_skills = [Charge.new(), Firespark.new(), Sprint.new()]
	var mage_skills = [Firespark.new(), Sprint.new(), Charge.new()]
	var rogue_skills = [Sprint.new(), Charge.new(), Firespark.new()]

	var curr_skills = warrior_skills if party_member.get_char_class() == "Warrior" else mage_skills if party_member.get_char_class() == "Mage" else rogue_skills

	skill1.update_node(party_member.spent_skill_points, curr_skills[0], remaining_points, party_member)
	skill2.update_node(party_member.spent_skill_points, curr_skills[1], remaining_points, party_member)
	skill3.update_node(party_member.spent_skill_points, curr_skills[2], remaining_points, party_member)

func _on_skill_unlocked(skill: Skill) :
	party_member.skill_list.append(skill)
	party_member.spend_skill_point()
	update_ui(party_member)
