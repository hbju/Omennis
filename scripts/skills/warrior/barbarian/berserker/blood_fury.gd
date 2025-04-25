extends Skill
class_name BloodFury

var damage := 0
var max_cooldown := 6
var duration := 3
var vampiric_strength = 33
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, _map: CombatMap) -> bool:
	var skill_target = _map.get_character(skill_pos)
	if is_valid_target_type(from, skill_target) :
		from.gain_vampiric_status(duration, vampiric_strength)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(caster: CombatCharacter, _potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	# Self buff - Vampiric
	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE * 1.1 # Good sustain buff

	# Value more if caster is lower health
	score += (1.0 - caster.health / caster.max_health) * AIScoringWeights.WEIGHT_HEAL_LOW_HP_BONUS

	# Value more if likely to deal damage soon
	var enemies_nearby = 0
	var caster_pos = map.get_cell_coords(caster.global_position)
	for p in map.get_alive_party_members():
		if HexHelper.distance(caster_pos, map.get_cell_coords(p.global_position)) <= caster.move_range + 1:
			enemies_nearby += 1
	score += enemies_nearby * 4.0

	if caster.char_statuses["vampiric"].size() > 0:
		score *= 0.8

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-cast only
	var caster_pos = map.get_cell_coords(caster.global_position)
	if is_valid_target_type(caster, caster):
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_CAST, caster, caster_pos, [caster]
		)]
	else:
		return []

	
func get_skill_name() -> String:
	return "Blood Fury"

func get_skill_description() -> String:
	return "For the next " + str(duration) + " turns, heal for " + str(vampiric_strength) + "% of the damage dealt."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/blood_fury.png")

func get_skill_range() -> int:
	return 0

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return true
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var cell = map.get_cell_coords(from.global_position)
	curr_highlighted_cells = [cell]
	map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)

	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
		if mouse_pos == cell:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8)
			
	return curr_highlighted_cells
