extends MarginContainer
class_name SkillTree

@export var debugging: bool = false
@export var skill_tooltip_scene: PackedScene

var skills: Array[SkillNode]

var party_member: PartyMember
var skill_tooltip_instance: Control # To hold the instantiated tooltip


func _ready() :
	if skill_tooltip_scene:
		skill_tooltip_instance = skill_tooltip_scene.instantiate()
		add_child(skill_tooltip_instance)
		skill_tooltip_instance.update_content(null)
		skill_tooltip_instance.set("top_level", true) 
		skill_tooltip_instance.reset_size()	
		skill_tooltip_instance.force_update_transform()
		skill_tooltip_instance.hide() 
		skill_tooltip_instance.z_index = 100 # Or another high value
	else:
		printerr("SkillTree: Skill Tooltip Scene not assigned!")

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

	if skill_tooltip_instance and is_instance_valid(hovered_node): 	

		skill_tooltip_instance.reset_size()
		skill_tooltip_instance.update_content(skill_data)
		skill_tooltip_instance.force_update_transform()

		# Get necessary info for positioning
		var node_rect = hovered_node.get_global_rect() 
		var tooltip_size = skill_tooltip_instance.size 
		var viewport_rect = get_viewport_rect()
		var offset = Vector2(10, 0) 

		var target_pos = node_rect.position + Vector2(node_rect.size.x, 0) + offset

		if target_pos.x + tooltip_size.x > viewport_rect.size.x:
			target_pos.x = node_rect.position.x - tooltip_size.x - offset.x

		if target_pos.y + tooltip_size.y > viewport_rect.size.y:
			target_pos.y = viewport_rect.size.y - tooltip_size.y # Stick to viewport bottom

		if target_pos.y < 0:
			target_pos.y = 0 

		if target_pos.x < 0:
			target_pos.x = 0 

		skill_tooltip_instance.global_position = target_pos
		skill_tooltip_instance.show()


func _on_skill_hover_exited():
	if skill_tooltip_instance:
		skill_tooltip_instance.hide()
