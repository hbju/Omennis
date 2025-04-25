extends Skill
class_name WarCry

var damage := 0
var max_cooldown := 4
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(_from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	if skill_pos in curr_highlighted_cells:
		for cell in curr_highlighted_cells :
			var character: CombatCharacter = map.get_character(cell)
			if character and character is PlayerCombatCharacter :
				character.gain_strong_status(2)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false
	
func get_skill_name() -> String:
	return "War Cry"

func get_skill_description() -> String:
	return "All allies in a 2-cell radius deal 50% more damage for two turns."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/war_cry.png")

func get_skill_range() -> int:
	return 1

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return true
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var can_attack = func(hex: Vector2i): return map.can_walk(hex)
	curr_highlighted_cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), can_attack)
	curr_highlighted_cells.erase(map.get_cell_coords(from.global_position))

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)
		var cell_char = map.get_character(cell)
		if cell_char and cell_char is PlayerCombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
		if cell_char and cell_char is AICombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 0)
			curr_highlighted_cells.erase(cell)
	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)
		if mouse_pos in curr_highlighted_cells:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8)
			
	return curr_highlighted_cells
