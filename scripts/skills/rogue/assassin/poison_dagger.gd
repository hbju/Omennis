# poison_dagger.gd
extends MeleeSkill
class_name PoisonDagger

var damage_mult: float = 2.0
var poison_damage_mult_per_turn: float = 1.0
var poison_duration: int = 3
var max_cooldown: int = 3

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	# Apply initial direct damage
	from.deal_damage(skill_target, damage_mult)
	from.attack(map.to_local(skill_target.global_position))
	
	# Apply the poison DoT
	# We can re-use the "decay" status logic. The 'level' will be the damage per turn.
	var poison_damage_per_turn = from.get_damage() * poison_damage_mult_per_turn
	skill_target.gain_status("poisoned", poison_duration, poison_damage_per_turn)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_MELEE
	
	# Score initial damage
	var initial_damage = caster.get_damage() * damage_mult
	score += initial_damage * AIScoringWeights.WEIGHT_DAMAGE
	
	if target.health <= initial_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS * 0.8 # Slightly less valuable as DoT is wasted
	else:
		score += (1.0 - (target.health / target.max_health)) * initial_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP

	# Score DoT component (Poison)
	var poison_damage = caster.get_damage() * poison_damage_mult_per_turn
	var total_dot_damage = poison_damage * poison_duration
	score += total_dot_damage * AIScoringWeights.WEIGHT_DAMAGE * 0.6 # DoT damage is less immediate, so score it lower
	score += AIScoringWeights.WEIGHT_BUFF_NEGATIVE * 0.7 # Value the status itself

	score -= target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY
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
func get_skill_name() -> String: return "Poison Dagger"
func get_skill_description() -> String:
	return "Apply poison to your dagger, dealing %.1fx your base damage immediately and applying a poison that deals %.1fx your base damage per turn for %d turns. Stacks.\nCooldown: %d turns." % [damage_mult, poison_damage_mult_per_turn, poison_duration, max_cooldown]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/poison_dagger.png") # Placeholder path
func target_allies() -> bool: return false
func target_enemies() -> bool: return true
func target_self() -> bool: return false