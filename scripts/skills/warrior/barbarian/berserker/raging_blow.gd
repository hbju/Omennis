extends MeleeSkill
class_name RagingBlow

var damage_mult := 5
var max_cooldown := 4

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var target = map.get_character(skill_pos)
	if is_valid_target_type(from, target) and skill_pos in curr_highlighted_cells:
		var actual_damage_mult = damage_mult
		if target.health < target.max_health * 3/10:
			actual_damage_mult *= 2
		from.deal_damage(target, actual_damage_mult)
		from.attack(map.to_local(target.global_position))
		cooldown = max_cooldown
		return true

	return false

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_MELEE # High potential damage melee attack
	var actual_damage_mult = damage_mult
	# Check execute condition
	if target.health < target.max_health * 0.3:
		actual_damage_mult *= 2
		score += 25.0 # Bonus for meeting execute condition

	var potential_damage = caster.get_damage() * actual_damage_mult
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE

	if target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		# Less bonus for low health here as execute is the main factor
		score += (1.0 - (target.health / target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP * 0.5

	score -= target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY
	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
		if cell != caster_pos:
			var target_char = map.get_character(cell)
			if target_char and is_valid_target_type(caster, target_char):
				targets.append(TargetInfo.new(
					TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
				))
	return targets

	
func get_skill_name() -> String:
	return "Raging Blow"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your basic damage to an enemy. It the enemy health is below 30%, deal double damage. "

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/raging_blow.png")

func get_skill_range() -> int:
	return 1

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false
	
func is_melee() -> bool:
	return true

