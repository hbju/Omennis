extends MeleeSkill
class_name Nightmare

var damage_mult: float = 4.0
var stun_duration: int = 2
var max_cooldown: int = 5

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	from.deal_damage(skill_target, damage_mult)
	skill_target.gain_status("stunned", stun_duration)
	
	from.attack(map.to_local(skill_target.global_position))

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	# This is an extremely high-value skill.
	var score = AIScoringWeights.WEIGHT_BASE_MELEE
	
	# Score the long stun. This is the main draw.
	score += AIScoringWeights.WEIGHT_DISABLE_TURN * stun_duration * 1.5 # Extra weight for a multi-turn stun
	
	# Score the high damage.
	var potential_damage = caster.get_damage() * damage_mult
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	
	if target.health <= potential_damage:
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
func get_skill_name() -> String: return "Nightmare"
func get_skill_description() -> String:
	return "Deal %.1fx base damage and stun an adjacent enemy for %d turns.\nCooldown: %d turns." % [damage_mult, stun_duration, max_cooldown]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/nightmare.png") # Placeholder
func target_allies() -> bool: return false
func target_enemies() -> bool: return true
func target_self() -> bool: return false