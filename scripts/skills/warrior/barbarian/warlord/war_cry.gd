extends Skill
class_name WarCry

var damage := 0
var max_cooldown := 4
var duration := 2
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(from.global_position)
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true).filter(map.can_walk)
	if skill_pos in aoe_cells:
		for cell in curr_highlighted_cells :
			var character: CombatCharacter = map.get_character(cell)
			if is_valid_target_type(from, character): # Is Ally?
				character.gain_status("strong", duration+1 if character == from else duration)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(caster: CombatCharacter, _potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE 

	var allies_affected: Array[CombatCharacter] = []
	var caster_pos = map.get_cell_coords(caster.global_position)
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true)

	for cell in aoe_cells:
		var character = map.get_character(cell)
		if is_valid_target_type(caster, character): # Is Ally?
			allies_affected.append(character)

	if allies_affected.is_empty(): return 0.0 # No value if no allies benefit

	# Score based on number of allies buffed and their potential damage output
	var buff_value_per_ally = AIScoringWeights.WEIGHT_BUFF_POSITIVE * duration * 0.3 # Estimate value of Strong
	score += allies_affected.size() * buff_value_per_ally * AIScoringWeights.WEIGHT_AOE_TARGET_ALLY_BUFF

	# Bonus if allies are near enemies
	var enemies_near_allies = 0
	for ally in allies_affected:
		var ally_pos = map.get_cell_coords(ally.global_position)
		for p in map.get_alive_party_members(): # Assuming AI vs Player
			if HexHelper.distance(ally_pos, map.get_cell_coords(p.global_position)) <= 2:
				enemies_near_allies += 1
				break # Count each ally only once
	score += enemies_near_allies * 5.0

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-activation, affects allies in radius
	var caster_pos = map.get_cell_coords(caster.global_position)
	var allies_affected: Array[CombatCharacter] = []
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true)

	for cell in aoe_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(caster, target_char): 
			allies_affected.append(target_char)

	if not allies_affected.is_empty():
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_AOE_ACTIVATION,
			caster,
			caster_pos,
			allies_affected
		)]
	else:
		return []

	
func get_skill_name() -> String:
	return "War Cry"

func get_skill_description() -> String:
	return "All allies in a " + str(get_skill_range()) + "-cell radius deal 50% more damage for " + str(duration) + " turns.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/war_cry.png")

func get_skill_range() -> int:
	return 3

func target_allies() -> bool:
	return true

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return false
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var can_attack = func(hex: Vector2i): return map.can_walk(hex)
	curr_highlighted_cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), can_attack)
	curr_highlighted_cells.erase(map.get_cell_coords(from.global_position))

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)
		var cell_char = map.get_character(cell)
		if cell_char and cell_char is PlayerCombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
		if cell_char and cell_char is AICombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 0)
			curr_highlighted_cells.erase(cell)
	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)
		if mouse_pos in curr_highlighted_cells:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8)
			
	return curr_highlighted_cells
