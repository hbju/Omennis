extends Skill
class_name GuardiansAura

var max_cooldown := 5
var duration := 2
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), func (_hex) : return true).filter(map.can_walk)
	if skill_pos in cells:
		for cell in cells :
			var character: CombatCharacter = map.get_character(cell)
			if is_valid_target_type(from, character):
				character.gain_defensive_status(duration+1)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(_caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	# AoE Ally Buff (Defensive)
	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE

	if potential_targets.is_empty(): return 0.0

	var buff_value_per_ally = AIScoringWeights.WEIGHT_BUFF_POSITIVE * duration * 0.7
	score += potential_targets.size() * buff_value_per_ally * AIScoringWeights.WEIGHT_AOE_TARGET_ALLY_BUFF

	# Value more if allies are low health or near enemies
	var low_hp_allies = 0
	var enemies_near_allies = 0
	for ally in potential_targets:
		if ally.health < ally.max_health * 0.6:
			low_hp_allies += 1
		var ally_pos = map.get_cell_coords(ally.global_position)
		for p in map.get_alive_party_members():
			if HexHelper.distance(ally_pos, map.get_cell_coords(p.global_position)) <= 2:
				enemies_near_allies += 1
				break
	score += low_hp_allies * 8.0
	score += enemies_near_allies * 4.0

	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-activation, affects adjacent allies + self
	var caster_pos = map.get_cell_coords(from.global_position)
	var allies_affected: Array[CombatCharacter] = []
	var aoe_cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), func (_hex) : return true).filter(map.can_walk)

	for cell in aoe_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(from, target_char):
			allies_affected.append(target_char)

	if not allies_affected.is_empty():
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_AOE_ACTIVATION,
			from,
			caster_pos,
			allies_affected
		)]
	else:
		return []

	
func get_skill_name() -> String:
	return "Guardian's Aura"

func get_skill_description() -> String:
	return "You and all adjacent allies take 50% less damage for " + str(duration) + " turns."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/guardians_aura.png")

func get_skill_range() -> int:
	return 1

func target_allies() -> bool:
	return true

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return true
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	curr_highlighted_cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), map.can_walk)
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
		elif map.get_character(cell):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
			
	return curr_highlighted_cells
