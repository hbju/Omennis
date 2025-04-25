extends Skill
class_name BasicSlash

var damage_mult := 2
var max_cooldown := 2

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	from.deal_damage(skill_target, damage_mult)
	from.attack(map.to_local(skill_target.global_position))
	cooldown = max_cooldown
	skill_finished.emit()

	return true

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0 # Cannot score without a target
	var target = potential_targets[0] # Basic slash is single target

	var score = AIScoringWeights.WEIGHT_BASE_MELEE # Base score for a possible action
	var potential_damage = from.get_damage() * damage_mult

	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE

	# Bonus for finishing blow
	if target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		# Bonus for damaging low health targets
		score += (1.0 - (target.health / target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP

	# Penalty for hitting heavily shielded targets
	score -= target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
		if cell != caster_pos: # Can't target self cell
			var target_char = map.get_character(cell)
			if target_char and is_valid_target_type(caster, target_char):
				targets.append(TargetInfo.new(
					TargetInfo.TargetType.CHARACTER,
					target_char,
					cell,
					[target_char] # Affected target is just the primary target
				))
	return targets
	
func get_skill_name() -> String:
	return "Basic Slash"

func get_skill_description() -> String:
	return "A basic attack that deals 10 damage to a nearby enemy."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/basic_slash.png")

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