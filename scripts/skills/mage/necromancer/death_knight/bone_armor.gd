extends Skill
class_name BoneArmor

var shield_amount := 50
var retaliate_damage := 20
var duration := 2
var max_cooldown := 5
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(from.global_position)
	if skill_pos != caster_pos:
		return false

	from.gain_shield(shield_amount)
	from.gain_thorn_status(duration, retaliate_damage)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func get_skill_name() -> String:
	return "Bone Armor"

func get_skill_description() -> String:
	return "Create a shield that absorbs " + str(shield_amount) + " damage and deals " + str(retaliate_damage) + " damage to any enemy that attacks you for " + str(duration) + " turns."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/bone_armor.png")

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
