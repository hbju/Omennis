extends MeleeSkill
class_name HolyStrike

var damage_mult := 4
var max_cooldown := 4
var heal_percentage := 0.25

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var target = map.get_character(skill_pos)
	if is_valid_target_type(from, target) and HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) <= get_skill_range():
		var damage = from.get_damage() * damage_mult
		from.deal_damage(target, damage_mult)
		from.heal(damage * heal_percentage)
		from.attack(map.to_local(target.global_position))
		cooldown = max_cooldown
		return true

	return false

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_MELEE # Melee Damage + Self Heal
	var potential_damage = caster.get_damage() * damage_mult
	var potential_heal = potential_damage * heal_percentage # Heal is 25% of damage

	# Score damage
	var damage_score = potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	if target.health <= potential_damage:
		damage_score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		damage_score += (1.0 - (target.health / target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
	damage_score -= target.shield * 0.1

	# Score heal
	var heal_score = potential_heal * AIScoringWeights.WEIGHT_HEAL
	heal_score += (1.0 - (caster.health / caster.max_health)) * potential_heal * AIScoringWeights.WEIGHT_HEAL_LOW_HP_BONUS

	score += damage_score + heal_score
	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Standard melee targeting
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(from.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func (_hex): return true).filter(map.can_walk)

	for cell in potential_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(from, target_char):
			targets.append(TargetInfo.new(
				TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
			))
	return targets
	
func get_skill_name() -> String:
	return "Holy Strike"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " 4 times your basic damage to an enemy and heal yourself for 25% of the damage dealt.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/holy_strike.png")

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

