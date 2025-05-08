extends MeleeSkill # Inherits range 1, is_melee, basic highlighting
class_name ArcaneSlash

var damage_mult := 3
var shield_gain_percent := 0.5 # Gain half of damage_mult dealt
var max_cooldown := 3

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	var caster_pos = map.get_cell_coords(from.global_position)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(caster_pos, skill_pos) > get_skill_range():
		return false 

	var damage_dealt = from.deal_damage(skill_target, damage_mult)
	from.gain_shield_flat(damage_dealt * shield_gain_percent)
	from.attack(map.to_local(skill_target.global_position))


	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_MELEE
	var potential_damage = from.get_damage() * damage_mult
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	score -= target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY

	if target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		score += (1.0 - (target.health / target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP

	# Score the shield gain
	var shield_gain = potential_damage * shield_gain_percent / 100.0
	var shield_value = shield_gain * AIScoringWeights.WEIGHT_SHIELD
	shield_value *= (1.0 + (1.0 - from.health / from.max_health) * 0.5)
	score += shield_value

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Standard melee targeting
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
	return "Arcane Slash"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to an enemy, gain " + str(shield_gain_percent) + "% of damage dealt as shield.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/arcane_slash.png")

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false
