extends Skill
class_name Frenzy

var damage := 0
var max_cooldown := 5
var curr_highlighted_cells: Array[Vector2i] = []
var duration := 4

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if is_valid_target_type(from, skill_target) :
		from.gain_status("vulnerable", duration+1)
		from.gain_status("strong", duration+1)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(caster: CombatCharacter, _potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	# Self buff (Strong + Vulnerable)
	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE # Base value, offset by risk

	# Calculate potential damage increase value
	var enemies_nearby = 0
	var caster_pos = map.get_cell_coords(caster.global_position)
	for p in map.get_alive_party_members():
		if HexHelper.distance(caster_pos, map.get_cell_coords(p.global_position)) <= caster.move_range + 1:
			enemies_nearby += 1
	# Rough estimate: Value based on potential extra damage over duration vs nearby enemies
	var potential_extra_damage = caster.get_damage() * 1.5 # Damage increase per attack
	score += enemies_nearby * potential_extra_damage * min(duration, 2) # Estimate 2 attacks over duration

	# Penalize for Vulnerable status
	score -= AIScoringWeights.WEIGHT_BUFF_NEGATIVE * 0.5  # Vulnerable is very risky
	# Penalize more if low health or already defensive (overrides defensive)
	if caster.health < caster.max_health * 0.6:
		score -= 20.0
	if caster.char_statuses["defensive"] > 0:
		score -= 10.0 # Losing defensive stance is bad

	# Less valuable if already strong
	if caster.char_statuses["strong"] > 0:
		score *= 0.3

	return max(0.0, score)

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var caster_pos = map.get_cell_coords(caster.global_position)
	if is_valid_target_type(caster, caster):
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_CAST, caster, caster_pos, [caster]
		)]
	else:
		return []
	
func get_skill_name() -> String:
	return "Frenzy"

func get_skill_description() -> String:
	return "Increase your damage by 50% and receive 50% more damage for " + str(duration) + " turns.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: yourself.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/frenzy.png")

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
