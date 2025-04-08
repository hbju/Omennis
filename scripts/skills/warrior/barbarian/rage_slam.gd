extends MeleeSkill
class_name RageSlam

var damage_mult := 2
var max_cooldown := 4

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	if skill_pos in curr_highlighted_cells:
		var damage = damage_mult * from.get_damage()
		var char_list = []
		for cell in curr_highlighted_cells :
			var character: CombatCharacter = map.get_character(cell)
			if character:
				char_list.append(character)

		for i in range(3):
			if char_list.size() > 0:
				print(char_list.size())
				var index = randi() % char_list.size()
				var character = char_list[index]
				char_list.erase(character)
				character.take_damage(damage)


		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false
	
func get_skill_name() -> String:
	return "Defensive Stance"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to up to three random adjacent characters."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/rage_slam.png")

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
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		if map.get_character(cell):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)


	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)

		if map.get_character(cell):
			if mouse_pos in curr_highlighted_cells :
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
			else : 
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)
			
	return curr_highlighted_cells

