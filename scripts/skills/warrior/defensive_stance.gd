extends Skill
class_name DefensiveStance

var damage := 0
var max_cooldown := 4
var curr_highlighted_cells: Array[Vector2i] = []
var duration := 3

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	if map.get_cell_coords(from.global_position) == skill_pos:
		from.gain_defensive_status(duration)
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false
	
func get_skill_name() -> String:
	return "Defensive Stance"

func get_skill_description() -> String:
	return "Reduce damage taken by 50% for three turns."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/defensive_stance.png")

func get_skill_range() -> int:
	return 0

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return true
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var cell = map.get_cell_coords(from.global_position)
	curr_highlighted_cells = [cell]
	map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)

	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
		if mouse_pos == cell:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8)
			
	return curr_highlighted_cells
