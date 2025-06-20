# blink.gd
extends Skill
class_name Blink

var max_cooldown: int = 5
var blink_range: int = 3
var next_spell_damage_bonus: int = 10 # +10 damage
var next_spell_damage_duration: int = 2

func use_skill(caster: CombatCharacter, target_cell: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(caster.global_position)

	if HexHelper.distance(caster_pos, target_cell) > blink_range or \
	   not map.can_walk(target_cell) or map.cell_occupied(target_cell):
		return false # Invalid target cell
	
	if not caster.teleport_to(target_cell) :
		return false

	caster.gain_status("imbue", next_spell_damage_duration, next_spell_damage_bonus)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(caster: CombatCharacter, _affected_targets: Array[CombatCharacter], target_cell: Vector2i, map: CombatMap) -> float:
	var score = AIScoringWeights.WEIGHT_BASE_MOBILITY

	# Score based on tactical advantage of the new position
	var caster_current_pos = map.get_cell_coords(caster.global_position)
	var enemies = [] # Get enemy list (e.g., map.get_alive_enemies_of(caster))
	for chara in map.characters: # Simplified enemy finding
		if chara is PlayerCombatCharacter : enemies.append(chara)

	# 1. Safety: Increase score if moving away from more enemies than moving towards
	var enemies_near_current = 0
	var enemies_near_target_cell = 0
	for enemy in enemies:
		var enemy_pos = map.get_cell_coords(enemy.global_position)
		if HexHelper.distance(caster_current_pos, enemy_pos) <= 2: enemies_near_current += 1
		if HexHelper.distance(target_cell, enemy_pos) <= 2: enemies_near_target_cell += 1
	
	if enemies_near_target_cell < enemies_near_current:
		score += (enemies_near_current - enemies_near_target_cell) * AIScoringWeights.WEIGHT_POSITIONING_SAFETY

	# 2. Offensive Positioning: Increase score if moving towards more enemies in range
	var targets_in_range_from_new_pos = 0
	var ranged = 4
	for enemy in enemies:
		if HexHelper.distance(target_cell, map.get_cell_coords(enemy.global_position)) > 1 and \
		   HexHelper.distance(target_cell, map.get_cell_coords(enemy.global_position)) <= ranged:
			targets_in_range_from_new_pos +=1
	score += targets_in_range_from_new_pos * 3.0

	# 3. Value the spell damage bonus
	# Estimate value: if there's a good target, the bonus is valuable.
	if not enemies.is_empty():
		score += (caster.get_damage() + next_spell_damage_bonus) * AIScoringWeights.WEIGHT_DAMAGE * 0.5 # Half weight for potential damage

	# Don't blink if already in a very safe/good spot and no offensive gain
	if enemies_near_current == 0 and targets_in_range_from_new_pos == 0 :
		score *= 0.1

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	if caster.char_statuses["rooted"] > 0 :
		return []
		
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)
	var potential_blink_cells = HexHelper.hex_reachable(caster_pos, blink_range, func (_hex): return true) \
		.filter(func(cell): return map.can_walk(cell) and cell != caster_pos and not map.cell_occupied(cell))
	print(potential_blink_cells)
	for cell in potential_blink_cells:
		targets.append(TargetInfo.new(
			TargetInfo.TargetType.CELL,
			null,
			cell,
			[] # No characters directly affected by targeting the cell
		))
	return targets

func get_skill_name() -> String: return "Blink"
func get_skill_description() -> String:
	return "Instantly teleport to an empty cell (Range: %d). Next turn, your base damage is increased by %d." % [blink_range, next_spell_damage_bonus] + \
		   "\nCooldown: %d turns." % max_cooldown
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/blink.png") 
func get_skill_range() -> int: return blink_range

func target_allies() -> bool: return false
func target_enemies() -> bool: return false
func target_self() -> bool: return false # Targets a cell

func is_melee() -> bool: return false

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	var curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, blink_range, map.can_walk)

	for cell in curr_highlighted_cells:
		if cell != caster_pos and not map.cell_occupied(cell):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1)

	return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	map.reset_map()
	var caster_pos = map.get_cell_coords(from.global_position)
	var curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, blink_range, map.can_walk)

	for cell in curr_highlighted_cells:
		if cell != caster_pos and not map.cell_occupied(cell):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1) # Highlight valid cells

	# If mouse is over a valid target cell, highlight it
	if mouse_pos in curr_highlighted_cells:
		map.set_cell(0, mouse_pos, 22, map.get_cell_atlas_coords(0, mouse_pos), 2) # Highlight hovered target cell
	return curr_highlighted_cells
