extends Skill
class_name ArcaneShield

var duration := 2
var max_cooldown := 3
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	var caster_pos = map.get_cell_coords(from.global_position)

	if not is_valid_target_type(from, skill_target) or HexHelper.distance(caster_pos, skill_pos) > get_skill_range():
		return false

	skill_target.gain_status("defensive", duration + 1 if skill_target == from else duration)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(_from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var target = potential_targets[0] # Single target buff

	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE # Base value of defensive buff

	var health_percent = target.health / target.max_health

	# More valuable on lower health targets
	score += (1.0 - health_percent) * AIScoringWeights.WEIGHT_HEAL_LOW_HP_BONUS * 0.5 # Use heal bonus weight but toned down

	# More valuable if target is likely to be attacked (e.g., is close to enemies)
	var nearby_enemies = 0
	var target_pos = map.get_cell_coords(target.global_position)
	for p in map.get_alive_party_members(): 
		if HexHelper.distance(target_pos, map.get_cell_coords(p.global_position)) <= 2:
			nearby_enemies+=1
	score += nearby_enemies * 5.0

	# Bonus if target currently has 'vulnerable' status
	if target.char_statuses["vulnerable"] > 0:
		score += AIScoringWeights.WEIGHT_SETUP_BONUS

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func (_hex): return true).filter(map.can_walk)

	for cell in potential_cells:
		var target_char = map.get_character(cell)
		# Check if the character is self OR a valid ally target
		if target_char and is_valid_target_type(caster, target_char):
			targets.append(TargetInfo.new(
				TargetInfo.TargetType.CHARACTER, # Targeting a specific character (self or ally)
				target_char,
				cell,
				[target_char] # The buff affects the targeted character
			))
	return targets


func get_skill_name() -> String:
	return "Arcane Shield"

func get_skill_description() -> String:
	return "Create a magical shield around an ally or yourself that reduces incoming damage by 50% for " + str(duration) + " turn. \n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/arcane_shield.png") 

func get_skill_range() -> int:
	return 2

func target_allies() -> bool:
	return true

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return true

func is_melee() -> bool:
	return false

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	var can_target = func(hex: Vector2i): return map.can_walk(hex)
	curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), can_target)

	var valid_targets: Array[Vector2i] = []
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)
		var character = map.get_character(cell)
		if cell == caster_pos or (character and character is PlayerCombatCharacter):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
			valid_targets.append(cell)
		elif character and character is AICombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 0) 

	curr_highlighted_cells = valid_targets
	return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	# Re-highlight potential range first
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(hex: Vector2i): return map.can_walk(hex))
	for cell in potential_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)

	# Highlight actual targets and hover effect
	for cell in curr_highlighted_cells: # Iterate only over valid targets
		var character = map.get_character(cell)
		var is_self = (cell == caster_pos)
		var is_ally = character and character is PlayerCombatCharacter

		if is_self or is_ally:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
			if mouse_pos == cell:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8)

	return curr_highlighted_cells
