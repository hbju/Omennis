extends Skill
class_name MeleeSkill

var curr_highlighted_cells: Array[Vector2i] = []

func get_skill_range() -> int:
	return 1
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var can_attack = func(hex: Vector2i): return map.can_walk(hex) && map.get_character(hex) and map.get_character(hex) is AICombatCharacter
	curr_highlighted_cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), can_attack)

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		var character = map.get_character(cell)
		if character and character is AICombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)

	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)

		var cell_character = map.get_character(cell)
		if cell_character and cell_character is AICombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)
			if mouse_pos == cell:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
			
	return curr_highlighted_cells

