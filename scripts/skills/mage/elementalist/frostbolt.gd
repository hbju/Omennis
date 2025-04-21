extends Skill
class_name Frostbolt
#TODO add root

var damage_mult := 2
var root_duration := 1
var max_cooldown := 3

const frostbolt_scene = preload("res://scenes/projectile_effect.tscn") # ASSUMPTION: You have a scene for the visual effect
var caster: CombatCharacter
var target: CombatCharacter
var curr_frostbolt: Node2D
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not skill_target or not skill_target is AICombatCharacter or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	curr_frostbolt = frostbolt_scene.instantiate()
	from.get_parent().add_child(curr_frostbolt)
	curr_frostbolt.position = from.position
	curr_frostbolt.scale = Vector2(1.5, 1.5)
	curr_frostbolt.speed = 1000.0
	curr_frostbolt.set_target_position(target.position)
	curr_frostbolt.target_reached.connect(_on_reached_target)

	cooldown = max_cooldown
	return true

func _on_reached_target():
	caster.deal_damage(target, damage_mult)
	target.gain_stunned_status(root_duration)
	curr_frostbolt.queue_free()
	skill_finished.emit()

func get_skill_name() -> String:
	return "Frostbolt"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage and root an enemy for " + str(root_duration) + " turn."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/frostbolt.png") # Placeholder path

func get_skill_range() -> int:
	return 4

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false

func is_melee() -> bool:
	return false

func highlight_targets(_from: CombatCharacter, _map: CombatMap) -> Array[Vector2i]:
	return []

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	curr_highlighted_cells = HexHelper.fov(map.get_cell_coords(from.global_position), mouse_pos, map.can_walk) 
	for cell in curr_highlighted_cells: 
		if HexHelper.distance(map.get_cell_coords(from.global_position), cell) > get_skill_range():
			curr_highlighted_cells.erase(cell)
			continue
		var cell_char = map.get_character(cell)
		if cell_char and cell_char is AICombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
		else :
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		

	return curr_highlighted_cells

