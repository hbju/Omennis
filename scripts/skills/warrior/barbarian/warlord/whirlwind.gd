extends Skill
class_name Whirlwind

var damage_mult := 5
var max_cooldown := 3

var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	if skill_pos in curr_highlighted_cells:
		for cell in curr_highlighted_cells :
			var target: CombatCharacter = map.get_character(cell)
			if target && target is AICombatCharacter :
				from.deal_damage(target, damage_mult)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false
	
func get_skill_name() -> String:
	return "Whirlwind"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to all adjacent enemies."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/whirlwind.png")

func get_skill_range() -> int:
	return 1

func target_allies() -> bool:
	return true

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

