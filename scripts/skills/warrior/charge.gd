extends Skill
class_name Charge

var damage_mult := 3
var max_cooldown := 3
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target):
		return false

	from.attack(map.to_local(skill_target.global_position))
	from.deal_damage(skill_target, damage_mult)
	cooldown = max_cooldown
	return true

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], target_cell: Vector2i, map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_RANGED
	var potential_damage = caster.get_damage() * damage_mult

	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE

	if target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		score += (1.0 - (target.health / target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP

	# Score the movement aspect (getting into melee)
	var current_pos = map.get_cell_coords(caster.global_position)
	var dist = HexHelper.distance(current_pos, target_cell)
	if dist > 1: # Only value the move if actually moving
		score += dist * AIScoringWeights.WEIGHT_POSITIONING_CLOSER * 0.5 # Less valuable than pure move as damage is main point

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Targets enemies along columns up to range
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)

	for i in range(6): # Check all 6 directions
		var current_cell = HexHelper.hex_neighbor(caster_pos, i)
		if not map.can_walk(current_cell) or map.cell_occupied(current_cell):
			continue # Skip this column if blocked

		for j in range(get_skill_range()+1):
			current_cell = HexHelper.hex_neighbor(current_cell, i)
			if not map.can_walk(current_cell):
				break # Stop checking this column if blocked

			if map.cell_occupied(current_cell) :
				var target_char = map.get_character(current_cell)
				if is_valid_target_type(caster, target_char):
					targets.append(TargetInfo.new(
						TargetInfo.TargetType.CHARACTER, target_char, current_cell, [target_char]
					))
				break
	return targets	

	
func get_skill_name() -> String:
	return "Charge"

func get_skill_description() -> String:
	return "Charge a target from up to three tiles away, dealing " + str(damage_mult) + " times your base damage.\n" + \
		"Can only target enemies not adjacent to you, in a straight line.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/basic_slash.png")

func get_skill_range() -> int:
	return 3

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false
	
func is_melee() -> bool:
	return false

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	curr_highlighted_cells = map.highlight_columns(map.get_cell_coords(from.global_position), get_skill_range())
	return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, _mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	return highlight_targets(from, map)