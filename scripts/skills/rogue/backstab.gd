extends MeleeSkill
class_name Backstab

var damage_mult: float = 2.0
var max_cooldown: int = 2

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false
	
	var attack_flags = {}
	if from.char_statuses.get("stealth", 0) > 0:
		attack_flags["guaranteed_crit"] = true

	from.deal_damage(skill_target, damage_mult, attack_flags)
	from.attack(map.to_local(skill_target.global_position))
	
	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_MELEE
	var is_stealthed = caster.char_statuses.get("stealth", 0) > 0
	var crit_multiplier = caster.character.crit_damage_multiplier if is_stealthed else 1.0
	
	var potential_damage = caster.get_damage() * damage_mult * crit_multiplier
	
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	
	if is_stealthed:
		score += 15.0 # Significant bonus for consuming stealth effectively

	if target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		score += (1.0 - (target.health / target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP

	score -= target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY
	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
		if cell != caster_pos:
			var target_char = map.get_character(cell)
			if is_valid_target_type(caster, target_char):
				targets.append(TargetInfo.new(
					TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
				))
	return targets

# --- Metadata and UI Functions ---
func get_skill_name() -> String: return "Backstab"
func get_skill_description() -> String:
	return "Deal %.1fx base damage to an adjacent enemy. Is always a critical hit when used from Stealth.\nCooldown: %d turns." % [damage_mult, max_cooldown]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/backstab.png") # Placeholder path
func target_allies() -> bool: return false
func target_enemies() -> bool: return true
func target_self() -> bool: return false