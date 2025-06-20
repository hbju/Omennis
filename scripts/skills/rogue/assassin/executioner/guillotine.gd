# guillotine.gd
extends MeleeSkill
class_name Guillotine

var damage_mult: float = 2.0
var crit_damage_mult: float = 4.0 # The multiplier if the hit is critical
var max_cooldown: int = 4

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	var attack_flags = {
		"custom_crit_damage": crit_damage_mult
		# We divide by the base crit multiplier to get the correct final value inside deal_damage
	}

	from.deal_damage(skill_target, damage_mult, attack_flags)
	from.attack(map.to_local(skill_target.global_position))
	
	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_MELEE
	
	var crit_chance = caster.get_crit_chance()

	var non_crit_damage = caster.get_damage() * damage_mult
	var crit_damage = caster.get_damage() * crit_damage_mult * caster.character.crit_damage_multiplier # Use the skill's specific multiplier
	var expected_damage = (non_crit_damage * (1 - crit_chance)) + (crit_damage * crit_chance)

	score += expected_damage * AIScoringWeights.WEIGHT_DAMAGE
	
	# If a crit is guaranteed and kills, this is a top-tier action
	if crit_chance == 1.0 and target.health <= crit_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS * 1.5
	elif target.health <= expected_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
		
	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Standard melee targeting
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
func get_skill_name() -> String: return "Guillotine"
func get_skill_description() -> String:
	return "Deal %.1fx base damage to an adjacent enemy. If the hit is critical, deal %.1fx base damage instead.\nCooldown: %d turns." % [damage_mult, crit_damage_mult, max_cooldown]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/guillotine.png") # Placeholder
func target_allies() -> bool: return false
func target_enemies() -> bool: return true
func target_self() -> bool: return false