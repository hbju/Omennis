extends Skill
class_name Whirlwind

var damage_mult := 5
var max_cooldown := 3

var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), map.can_walk)
	if skill_pos in cells:
		for cell in cells:
			var target: CombatCharacter = map.get_character(cell)
			if is_valid_target_type(from, target):
				from.deal_damage(target, damage_mult)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	# AoE Melee Damage (Adjacent Enemies)
	# potential_targets should be adjacent enemies hit
	if potential_targets.is_empty(): return 0.0

	var score = AIScoringWeights.WEIGHT_BASE_MELEE # Base for melee AoE
	var potential_damage_per_target = caster.get_damage() * damage_mult
	var total_enemy_damage_score = 0.0

	for target in potential_targets:
		var enemy_score = potential_damage_per_target * AIScoringWeights.WEIGHT_DAMAGE
		if target.health <= potential_damage_per_target:
			enemy_score += AIScoringWeights.WEIGHT_KILL_BONUS
		else:
			enemy_score += (1.0 - (target.health / target.max_health)) * potential_damage_per_target * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
		total_enemy_damage_score += enemy_score

	score += total_enemy_damage_score * AIScoringWeights.WEIGHT_AOE_TARGET_ENEMY

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-activation, affects adjacent enemies
	var caster_pos = map.get_cell_coords(caster.global_position)
	var enemies_affected: Array[CombatCharacter] = []
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in aoe_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(caster, target_char): # Checks target_enemies
			enemies_affected.append(target_char)

	if not enemies_affected.is_empty():
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_AOE_ACTIVATION,
			caster,
			caster_pos,
			enemies_affected
		)]
	else:
		return []

	
func get_skill_name() -> String:
	return "Whirlwind"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to all adjacent enemies."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/whirlwind.png")

func get_skill_range() -> int:
	return 1

func target_allies() -> bool:
	return false

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
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1)
		var character = map.get_character(cell)
		if character and character is AICombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		if character and character is PlayerCombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)

	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1)
		if mouse_pos in curr_highlighted_cells:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 2)

		var cell_character = map.get_character(cell)
		if cell_character :
			if cell_character is AICombatCharacter:
				if mouse_pos in curr_highlighted_cells:
					map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
				else:
					map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
			if cell_character is PlayerCombatCharacter:
				if mouse_pos in curr_highlighted_cells:
					map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8)
				else:
					map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)

			
	return curr_highlighted_cells

