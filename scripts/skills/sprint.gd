extends Skill
class_name Sprint

var damage := 0
var max_cooldown := 2
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	print(skill_pos)
	if map.can_walk(skill_pos) and !map.cell_occupied(skill_pos) and HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) <= get_skill_range():
		from.move_to(map.map_to_local(skill_pos))
		cooldown = max_cooldown
		return true

	return false
	
func get_skill_name() -> String:
	return "Sprint"

func get_skill_description() -> String:
	return "Move quickly to a nearby empty space."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/sprint.png")

func get_skill_range() -> int:
	return 2

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return false
	
func is_melee() -> bool:
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var can_sprint_to = func(hex: Vector2i): return map.can_walk(hex) and !map.cell_occupied(hex)
	curr_highlighted_cells = HexHelper.hex_reachable(map.get_cell_coords(from.global_position), get_skill_range(), can_sprint_to)
	curr_highlighted_cells.erase(map.get_cell_coords(from.global_position))
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1)

	return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1)
		if mouse_pos == cell:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
			
	return curr_highlighted_cells
