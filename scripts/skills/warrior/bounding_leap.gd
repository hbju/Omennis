# bounding_leap.gd
extends Skill
class_name BoundingLeap

var damage_mult: float = 1 # Minor damage
var max_cooldown: int = 3
var leap_range: int = 3
var knockback_strength: int = 1 # Knockback distance
var aoe_radius_on_land: int = 1 # Affects adjacent cells

func use_skill(caster: CombatCharacter, target_cell: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(caster.global_position)

	# Check if target_cell is within leap_range and is walkable & not occupied by caster
	if HexHelper.distance(caster_pos, target_cell) > leap_range or \
	   not map.can_walk(target_cell) or map.cell_occupied(target_cell): 
			return false # Cannot land on cell occupied by another character.

	caster.move_to(map.map_to_local(target_cell))

	# --- Apply AoE Damage and Knockback on Landing ---
	var landing_aoe_cells = HexHelper.hex_reachable(target_cell, aoe_radius_on_land, func(_hex): return true)
	var affected_by_aoe: Array[CombatCharacter] = []

	for cell_in_aoe in landing_aoe_cells:
		if cell_in_aoe == target_cell: continue # Don't hit cell leaped onto, but adjacent

		var char_in_aoe = map.get_character(cell_in_aoe)
		if char_in_aoe and is_valid_target_type(caster, char_in_aoe): # Hits enemies
			affected_by_aoe.append(char_in_aoe)

	for enemy_hit in affected_by_aoe:
		caster.deal_damage(enemy_hit, damage_mult)

		# Determine knockback direction (away from landing spot)
		var direction = -1

		var enemy_cell = map.get_cell_coords(enemy_hit.global_position)
		for dir_idx in range(6):
			if HexHelper.hex_neighbor(target_cell, dir_idx) == enemy_cell:
				direction = dir_idx
				break
		if direction != -1:
			# Use knockback_damage = 0 if no damage on knockback itself from this skill
			enemy_hit.knockback(knockback_strength, direction, 0)

	cooldown = max_cooldown
	return true

func score_action(caster: CombatCharacter, affected_targets: Array[CombatCharacter], target_cell: Vector2i, map: CombatMap) -> float:
	var score = AIScoringWeights.WEIGHT_BASE_RANGED 

	# Score based on enemies hit by AoE
	var total_damage_dealt = 0.0
	for target in affected_targets: # affected_targets are those hit by the landing AoE
		if is_valid_target_type(caster, target): # Is an enemy
			var damage_to_this_target = caster.get_damage() * damage_mult
			total_damage_dealt += damage_to_this_target
			if target.health <= damage_to_this_target:
				score += AIScoringWeights.WEIGHT_KILL_BONUS # Half bonus as it's AoE
			score -= target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY

	score += total_damage_dealt * AIScoringWeights.WEIGHT_DAMAGE

	# Score positioning advantage (e.g., moving closer to a primary target or to safety)
	var caster_current_pos = map.get_cell_coords(caster.global_position)
	# Example: Value getting closer to lowest HP enemy OR flanking
	var players = map.get_alive_party_members() # Assuming AI is targeting players
	if not players.is_empty():
		var primary_target = players[0] # Find lowest HP for example
		for p in players: if p.health < primary_target.health: primary_target = p

		var dist_before = HexHelper.distance(caster_current_pos, map.get_cell_coords(primary_target.global_position))
		var dist_after = HexHelper.distance(target_cell, map.get_cell_coords(primary_target.global_position))
		score += (dist_before - dist_after) * AIScoringWeights.WEIGHT_POSITIONING_CLOSER

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)
	var potential_landing_cells = HexHelper.hex_reachable(caster_pos, leap_range, map.can_walk)

	for landing_cell in potential_landing_cells:
		if landing_cell == caster_pos or map.cell_occupied(landing_cell):
			continue

		# Determine who would be hit by the AoE if landing here
		var affected_by_aoe_on_land: Array[CombatCharacter] = []
		var landing_aoe_cells = HexHelper.hex_reachable(landing_cell, aoe_radius_on_land, func(_h):return true)
		for cell_in_aoe in landing_aoe_cells:
			if cell_in_aoe == landing_cell: continue # AoE is adjacent to landing
			var char_in_aoe = map.get_character(cell_in_aoe)
			if is_valid_target_type(caster, char_in_aoe):
				affected_by_aoe_on_land.append(char_in_aoe)

		# Add this leap destination if it provides an offensive opportunity or is just a valid move
		targets.append(TargetInfo.new(
			TargetInfo.TargetType.CELL, # Primary target is the landing cell
			null,
			landing_cell,
			affected_by_aoe_on_land # Characters hit by the landing shockwave
		))
	return targets

func get_skill_name() -> String: return "Bounding Leap"
func get_skill_description() -> String:
	return "Leap to a cell in a %d-cell radius. Enemies adjacent to your landing spot take %.2fx base damage and are knockbacked." % [leap_range, damage_mult] + \
		   "\nCooldown: %d turns." % max_cooldown
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/bounding_leap.png") # Placeholder
func get_skill_range() -> int: return leap_range # This is range to the landing cell

func target_allies() -> bool: return false
func target_enemies() -> bool: return true # The AoE part targets enemies
func target_self() -> bool: return false # Targets a cell

func is_melee() -> bool: return false # It's a movement/AoE initiation

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	var curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, leap_range, func(_hex: Vector2i): return true).filter(func (cell): return map.can_walk((cell)))

	for cell in curr_highlighted_cells:
		if map.cell_occupied(cell):
			continue 
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1)

	return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	map.reset_map()

	var caster_pos = map.get_cell_coords(from.global_position)
	var curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, leap_range, func(_hex: Vector2i): return true).filter(func (cell): return map.can_walk((cell)))
	for cell in curr_highlighted_cells:
		if map.cell_occupied(cell):
			continue 
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1)

	# If mouse is over a valid center point, highlight the AoE
	if mouse_pos in curr_highlighted_cells and not map.cell_occupied(mouse_pos):
		map.set_cell(0, mouse_pos, 22, map.get_cell_atlas_coords(0, mouse_pos), 2) # Hovered target cell
		var curr_aoe_highlight = HexHelper.hex_reachable(mouse_pos, aoe_radius_on_land, func(hex): return map.can_walk(hex))

		for cell in curr_aoe_highlight:
			var character = map.get_character(cell)
			if is_valid_target_type(from, character):
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)

	return curr_highlighted_cells # Return the valid center points