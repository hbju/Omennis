extends Skill
class_name Inquisition

var damage_mult := 3
var max_cooldown := 5

var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), map.can_walk)
	if skill_pos in cells:
		var damage = damage_mult * from.get_damage()
		for cell in cells :
			var character: CombatCharacter = map.get_character(cell)
			if character:
				if from is PlayerCombatCharacter :
					if character is PlayerCombatCharacter :
						character.heal(damage)
					if character is AICombatCharacter :
						from.deal_damage(character, damage_mult)
				if from is AICombatCharacter :
					if character is PlayerCombatCharacter :
						from.deal_damage(character, damage_mult)
					if from is AICombatCharacter :
						character.heal(damage)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false

func score_action(caster: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	# AoE Damage (Enemies) + Heal (Allies)
	var score = AIScoringWeights.WEIGHT_BASE_MELEE

	var potential_damage = caster.get_damage() * damage_mult
	var potential_heal = potential_damage # Heal amount equals damage dealt

	var total_enemy_damage_score = 0.0
	var total_ally_heal_score = 0.0
	var enemies_hit = 0
	var allies_healed = 0

	for target in potential_targets:
		if target is PlayerCombatCharacter: # Is Enemy?
			enemies_hit += 1
			var enemy_score = potential_damage * AIScoringWeights.WEIGHT_DAMAGE
			if target.health <= potential_damage:
				enemy_score += AIScoringWeights.WEIGHT_KILL_BONUS
			else:
				enemy_score += (1.0 - (target.health / target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
			total_enemy_damage_score += enemy_score
		else: # Is Ally?
			allies_healed += 1
			var heal_score = min(potential_heal, target.max_health - target.health) * AIScoringWeights.WEIGHT_HEAL
			heal_score += (1.0 - (target.health / target.max_health)) * potential_heal * AIScoringWeights.WEIGHT_HEAL_LOW_HP_BONUS
			total_ally_heal_score += heal_score

	if enemies_hit == 0 and allies_healed == 0: return 0.0 # No effect

	score += total_enemy_damage_score * AIScoringWeights.WEIGHT_AOE_TARGET_ENEMY
	score += total_ally_heal_score * AIScoringWeights.WEIGHT_AOE_TARGET_ALLY_HEAL

	return max(0.0, score)

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-activation, affects allies (heal) and enemies (damage) in radius
	var caster_pos = map.get_cell_coords(caster.global_position)
	var characters_affected: Array[CombatCharacter] = []
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func (_hex) : return true).filter(map.can_walk)

	for cell in aoe_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(caster, target_char): # Affects others
			characters_affected.append(target_char)


	if characters_affected.size() > 0: # Only generate if it hits *someone* relevant
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_AOE_ACTIVATION,
			caster,
			caster_pos,
			characters_affected # Contains both allies and enemies
		)]
	else:
		return []


	
func get_skill_name() -> String:
	return "Inquisition"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to all enemies and heal all allies within a " + str(get_skill_range()) +"-cell radius for as much.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/inquisition.png")

func get_skill_range() -> int:
	return 2

func target_allies() -> bool:
	return true

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	curr_highlighted_cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), map.can_walk)
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

