extends Skill
class_name BoneArmor

var shield_amount := 50
var retaliate_damage := 20
var duration := 2
var max_cooldown := 5
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var target = map.get_character(skill_pos)
	if not is_valid_target_type(from, target):
		return false

	from.gain_shield(shield_amount)
	from.gain_thorn_status(duration, retaliate_damage)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(caster: CombatCharacter, _potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	# Self buff: Shield + Thorns
	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE * 1.2 # Base for strong defensive buff

	# Score shield
	var shield_value = shield_amount * AIScoringWeights.WEIGHT_SHIELD
	shield_value *= (1.0 + (1.0 - caster.health / caster.max_health) * 0.5) # More valuable when low hp
	score += shield_value

	# Score thorns - more valuable if enemies are likely to attack caster
	var enemies_nearby = 0
	var caster_pos = map.get_cell_coords(caster.global_position)
	for p in map.get_alive_party_members():
		# Check if enemy is melee and adjacent
		if HexHelper.distance(caster_pos, map.get_cell_coords(p.global_position)) == 1: # Add check for melee capability if possible
			enemies_nearby += 1
	score += enemies_nearby * retaliate_damage * 0.3 * duration # Approx value of thorns damage

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-cast only
	var caster_pos = map.get_cell_coords(caster.global_position)
	if is_valid_target_type(caster, caster):
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_CAST, caster, caster_pos, [caster]
		)]
	else:
		return []


func get_skill_name() -> String:
	return "Bone Armor"

func get_skill_description() -> String:
	return "Create a shield that absorbs " + str(shield_amount) + " damage and deals " + str(retaliate_damage) + " damage to any enemy that attacks you for " + str(duration) + " turns."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/bone_armor.png")

func get_skill_range() -> int:
	return 0

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return true

func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var cell = map.get_cell_coords(from.global_position)
	curr_highlighted_cells = [cell]
	map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
		if mouse_pos == cell:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8)
	return curr_highlighted_cells
