extends Skill
class_name MoltenBlade

var bonus_damage = 15
var duration := 4
var max_cooldown := 5
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var target_char = map.get_character(skill_pos)
	if not is_valid_target_type(from, target_char) :
		return false

	from.gain_status("imbue", duration+1, bonus_damage)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(from: CombatCharacter, _potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	# Self buff - Score based on potential future damage increase
	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE # Base value for a buff

	# More valuable if caster is likely to attack multiple times soon
	# Hard to predict, use a base value + bonus if enemies are close
	var caster_pos = map.get_cell_coords(from.global_position)
	for p in map.get_alive_party_members(): # Assuming AI vs Player
		var dist = HexHelper.distance(caster_pos, map.get_cell_coords(p.global_position))
		score += AIScoringWeights.WEIGHT_SKILL_DISTANCE * 2.0/dist # Distance penalty

	# less valuable if low health
	score += AIScoringWeights.WEIGHT_SKILL_LOW_HEALTH * (1 - from.health / from.max_health) # Health penalty

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-cast only
	var caster_pos = map.get_cell_coords(caster.global_position)
	if is_valid_target_type(caster, caster): # Should always be true for target_self=true
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_CAST,
			caster,
			caster_pos,
			[caster] # Affects the caster
		)]
	else:
		return []


func get_skill_name() -> String:
	return "Molten Blade"

func get_skill_description() -> String:
	return "Imbue your weapon with fire, dealing " + str(bonus_damage) + " additional base damage for " + str(duration) + " turns.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: yourself.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/molten_blade.png") 

func get_skill_range() -> int:
	return 0 # Self cast

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return true

func is_melee() -> bool:
	# Consistent with other self-buffs (Defensive Stance, Frenzy)
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	# Highlight self only, similar to Defensive Stance
	var cell = map.get_cell_coords(from.global_position)
	curr_highlighted_cells = [cell]
	map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7) # Use self-target color
	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	# Highlight self when hovered, similar to Defensive Stance
	for cell in curr_highlighted_cells: # Should only be self cell
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7) # Default self color
		if mouse_pos == cell:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8) # Hovered self color
	return curr_highlighted_cells