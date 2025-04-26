extends Skill
class_name DefensiveStance

var max_cooldown := 4
var curr_highlighted_cells: Array[Vector2i] = []
var duration := 4

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if is_valid_target_type(from, skill_target):
		from.gain_status("defensive", duration+1)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(from: CombatCharacter, _potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	# Self buff
	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE

	var health_percent = from.health / from.max_health
	score += (1.0 - health_percent) * AIScoringWeights.WEIGHT_HEAL_LOW_HP_BONUS * 0.6 # Value more when low HP

	# Value more if likely to be attacked
	var enemies_nearby = 0
	var caster_pos = map.get_cell_coords(from.global_position)
	for p in map.get_alive_party_members():
		if HexHelper.distance(caster_pos, map.get_cell_coords(p.global_position)) <= 3:
			enemies_nearby += 1
	score += enemies_nearby * 6.0

	if from.char_statuses["vulnerable"] > 0:
		score += AIScoringWeights.WEIGHT_SETUP_BONUS # Removes vulnerable

	if from.char_statuses["defensive"] > 0:
		score *= 0.3 # Less value if already defensive

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var caster_pos = map.get_cell_coords(caster.global_position)
	if is_valid_target_type(caster, caster):
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_CAST, caster, caster_pos, [caster]
		)]
	else:
		return []

	
func get_skill_name() -> String:
	return "Defensive Stance"

func get_skill_description() -> String:
	return "Reduce damage taken by 50% for " + str(duration) + " turns.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: yourself.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/defensive_stance.png")

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
