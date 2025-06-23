# final_strike.gd
extends MeleeSkill
class_name FinalStrike

var damage_mult: float = 1.0
var execute_threshold: float = 0.3 # 30% health
var execute_damage_mult: float = 6.0
var max_cooldown: int = 1

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	var final_damage_mult = damage_mult
	if skill_target.health < skill_target.max_health * execute_threshold:
		final_damage_mult = execute_damage_mult

	from.deal_damage(skill_target, final_damage_mult)
	from.attack(map.to_local(skill_target.global_position))

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_MELEE
	
	var actual_damage_mult = damage_mult
	if target.health < target.max_health * execute_threshold:
		actual_damage_mult = execute_damage_mult
		score += 50.0 # Huge bonus for meeting the execute condition

	var potential_damage = caster.get_damage() * actual_damage_mult
	
	# This skill is primarily for killing, so its value is almost entirely in the kill shot.
	if target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS * 2.0 # Extra bonus because it's an execute


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
func get_skill_name() -> String: return "Final Strike"
func get_skill_description() -> String:
	return "Deal %.1fx base damage to an adjacent enemy. If its health is below %d%%, deal %.1fx base damage instead.\nCooldown: %d turns." % [damage_mult, execute_threshold * 100, execute_damage_mult, max_cooldown]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/final_strike.png") # Placeholder
func target_allies() -> bool: return false
func target_enemies() -> bool: return true
func target_self() -> bool: return false