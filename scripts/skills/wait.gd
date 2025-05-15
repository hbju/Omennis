extends Skill
class_name WaitSKill

var max_cooldown := 0

func use_skill(_from: CombatCharacter, _skill_pos: Vector2i, _map: CombatMap) -> bool:
	skill_finished.emit()
	return true
	
func get_skill_name() -> String:
	return "Wait"

func get_skill_description() -> String:
	return "Wait for this turn."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/wait.png")

func get_skill_range() -> int:
	return 0

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return false

func target_self() -> bool:
	return false
	
func is_melee() -> bool:
	return false

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	map.set_cell(0, caster_pos, 22, map.get_cell_atlas_coords(0, caster_pos), 1)
	return [caster_pos]

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	if caster_pos == mouse_pos and is_valid_target_type(from, map.get_character(caster_pos)):
		map.set_cell(0, caster_pos, 22, map.get_cell_atlas_coords(0, caster_pos), 2)
	else:
		map.set_cell(0, caster_pos, 22, map.get_cell_atlas_coords(0, caster_pos), 1)
	return [caster_pos]