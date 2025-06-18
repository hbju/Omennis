extends MeleeSkill
class_name RageSlam

var damage_mult := 4
var max_cooldown := 4
var targets_number := 3

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), map.can_walk)
	if skill_pos in cells:
		var char_list = []
		for cell in cells:
			var character: CombatCharacter = map.get_character(cell)
			if is_valid_target_type(from, character):
				char_list.append(character)

		char_list.shuffle()
		char_list = char_list.slice(0, targets_number)
		for character in char_list:
			from.deal_damage(character, damage_mult)


		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	# AoE Melee - Hits up to 3 random adjacent characters
	# Score based on expected hits on enemies vs allies
	var score = AIScoringWeights.WEIGHT_BASE_MELEE
	var potential_damage = caster.get_damage() * damage_mult

	if potential_targets.size() == 0:
		return 0.0

	var combinations = []
	if potential_targets.size() <= targets_number:
		combinations.append(potential_targets)
	else:
		for i in range(potential_targets.size() - targets_number + 1):
			for j in range(i + 1, potential_targets.size()):
				for k in range(j + 1, potential_targets.size()):
					combinations.append([potential_targets[i], potential_targets[j], potential_targets[k]])



	var expected_ally_hits = 0.0
	var enemy_damage_score = 0.0
	for combination in combinations:
		for target in combination:
			if target and target is PlayerCombatCharacter:
				enemy_damage_score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE
				if target.health < potential_damage :
					enemy_damage_score += AIScoringWeights.WEIGHT_KILL_BONUS
				else :
					enemy_damage_score += potential_damage * (1 - target.health / target.max_health) * AIScoringWeights.WEIGHT_DAMAGE_PER_HP # Scale damage based on target health
			elif target and target is AICombatCharacter:
				expected_ally_hits += 1

	# Penalize expected damage to allies
	enemy_damage_score /= combinations.size() # Average score
	var ally_penalty = expected_ally_hits * AIScoringWeights.WEIGHT_AOE_TARGET_ALLY_DAMAGE_PENALTY / 10 / combinations.size() # Scale penalty

	score += enemy_damage_score + ally_penalty
	return max(0.0, score)

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var caster_pos = map.get_cell_coords(caster.global_position)
	var adjacent_chars: Array[CombatCharacter] = []
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
			var target_char = map.get_character(cell)
			if is_valid_target_type(caster, target_char):
				adjacent_chars.append(target_char)

	if not adjacent_chars.is_empty():
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_AOE_ACTIVATION, # Activation type
			caster,
			caster_pos,
			adjacent_chars # List of *all* adjacent characters (random selection later)
		)]
	return []

	
func get_skill_name() -> String:
	return "Rage Slam"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to up to " + str(targets_number) + " random adjacent characters.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/rage_slam.png")

func get_skill_range() -> int:
	return 1

func target_allies() -> bool:
	return true

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var can_attack = func(hex: Vector2i): return map.can_walk(hex)
	curr_highlighted_cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), can_attack)
	curr_highlighted_cells.erase(map.get_cell_coords(from.global_position))
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		if map.get_character(cell):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)


	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)

		if map.get_character(cell):
			if mouse_pos in curr_highlighted_cells :
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
			else : 
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)
			
	return curr_highlighted_cells

