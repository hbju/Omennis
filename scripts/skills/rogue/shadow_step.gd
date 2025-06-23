extends Skill
class_name ShadowStep

var max_cooldown: int = 3
var stealth_duration: int = 1
var skill_range = 2

func use_skill(caster: CombatCharacter, target_cell: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(caster.global_position)

	# Check if target_cell is valid: in range, walkable, and not occupied.
	if HexHelper.distance(caster_pos, target_cell) > get_skill_range() or \
	   not map.can_walk(target_cell) or map.cell_occupied(target_cell):
		return false

	if not caster.teleport_to(target_cell) : 
		return false
		
	caster.gain_status("stealth", stealth_duration + 1) # +1 to last through their next turn start

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(caster: CombatCharacter, _affected_targets: Array[CombatCharacter], target_cell: Vector2i, map: CombatMap) -> float:
	var score = AIScoringWeights.WEIGHT_BASE_MOBILITY * 1.5 # High value for repositioning + stealth

	var caster_current_pos = map.get_cell_coords(caster.global_position)
	var enemies = map.get_alive_party_members()

	# 1. Safety: Moving away from threats is good.
	var enemies_near_current = 0
	for enemy in enemies:
		if HexHelper.distance(caster_current_pos, map.get_cell_coords(enemy.global_position)) <= 2:
			enemies_near_current += 1
	score += enemies_near_current * AIScoringWeights.WEIGHT_POSITIONING_SAFETY * 0.5

	# 2. Offensive Positioning: Moving to a flanking position or closer to a priority target is better.
	if not enemies.is_empty():
		var primary_target = enemies[0] # Example: target lowest health
		for p in enemies:
			if p.health < primary_target.health:
				primary_target = p
		
		var dist_before = HexHelper.distance(caster_current_pos, map.get_cell_coords(primary_target.global_position))
		var dist_after = HexHelper.distance(target_cell, map.get_cell_coords(primary_target.global_position))

		score += (dist_before - dist_after) * AIScoringWeights.WEIGHT_POSITIONING_CLOSER

	# 3. Stealth Value: Stealth is inherently valuable.
	score += 5.0 # Flat bonus for gaining stealth.

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	if caster.char_statuses["rooted"] > 0 : 
		return targets

	var caster_pos = map.get_cell_coords(caster.global_position)
	# Find all empty, walkable cells within range.
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true).filter(func (hex) : return map.can_walk(hex) and not map.cell_occupied(hex))

	for cell in potential_cells:
		if cell != caster_pos:
			targets.append(TargetInfo.new(
				TargetInfo.TargetType.CELL, null, cell, []
			))
	return targets

func get_skill_name() -> String: return "Shadow Step"
func get_skill_description() -> String:
	return "Instantly move to a cell within a %d-cell radius, entering Stealth for %d turn.\nCooldown: %d turns." % [get_skill_range(), stealth_duration, max_cooldown]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/shadow_step.png") # Placeholder path
func get_skill_range() -> int: return skill_range
func is_melee() -> bool: return false
func target_allies() -> bool: return false
func target_enemies() -> bool: return false
func target_self() -> bool: return false # Targets a cell

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	var valid_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true).filter(func (hex) : return map.can_walk(hex) and not map.cell_occupied(hex))
	valid_cells.erase(caster_pos)
	for cell in valid_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1)
	return valid_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var valid_cells = highlight_targets(_from, map)
	if mouse_pos in valid_cells:
		map.set_cell(0, mouse_pos, 22, map.get_cell_atlas_coords(0, mouse_pos), 2)
	return valid_cells