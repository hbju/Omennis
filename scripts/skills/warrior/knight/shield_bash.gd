extends MeleeSkill
class_name ShieldBash

var damage_mult := 2
var max_cooldown := 3
var duration := 2

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var target = map.get_character(skill_pos)
	if is_valid_target_type(from, target) and HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) <= get_skill_range():
		target.gain_weak_status(duration + 1)
		from.deal_damage(target, damage_mult)
		from.attack(map.to_local(target.global_position))
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_MELEE # Melee Damage + Debuff
	var potential_damage = caster.get_damage() * damage_mult

	# Score damage
	var damage_score = potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	if target.health <= potential_damage:
		damage_score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		damage_score += (1.0 - (target.health / target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
	damage_score -= target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY

	# Score debuff (Weak)
	var debuff_score = AIScoringWeights.WEIGHT_BUFF_NEGATIVE * duration
	if target.char_statuses["weak"] > 0:
		debuff_score *= 0.8 
	if target.char_statuses["strong"] > 0:
		debuff_score *= 1.5

	score += damage_score + debuff_score
	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Standard melee targeting
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(caster, target_char):
			targets.append(TargetInfo.new(
				TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
			))
	return targets

	
func get_skill_name() -> String:
	return "Shield Bash"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage and reduce the enemy’s damage by 33% for " + str(duration) + " turns. "

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/shield_bash.png")

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

