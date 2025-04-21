extends Skill
class_name MoltenBlade

var bonus_damage = 10
var duration := 3
var max_cooldown := 4
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(from.global_position)
	if skill_pos != caster_pos:
		return false

	from.gain_imbue_status(duration, bonus_damage)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func get_skill_name() -> String:
	return "Molten Blade"

func get_skill_description() -> String:
	return "Imbue your weapon with fire, dealing " + str(bonus_damage) + " additional base damage for " + str(duration) + " turns."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/molten_blade.png") # Placeholder path

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