extends Skill
class_name DrainLife

var damage_mult := 2
var max_cooldown := 4

const drain_life_effect = preload("res://scenes/projectile_effect.tscn") # ASSUMPTION: Beam/effect visual
var caster: CombatCharacter
var target: CombatCharacter
var curr_effect: ProjectileEffect
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not skill_target or not skill_target is CombatCharacter or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	curr_effect = drain_life_effect.instantiate()
	from.get_parent().add_child(curr_effect)
	curr_effect.position = from.position
	curr_effect.scale = Vector2(1.5, 1.5)
	curr_effect.speed = 1000.0
	curr_effect.set_target_position(target.position)
	curr_effect.target_reached.connect(_on_reached_target, CONNECT_ONE_SHOT)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func _on_reached_target():
	if is_instance_valid(target):
		_apply_effect()
	if is_instance_valid(curr_effect):
		curr_effect.queue_free()

func _apply_effect():
	if is_instance_valid(target) and is_instance_valid(caster):
		caster.deal_damage(target, damage_mult)
		caster.heal(damage_mult * caster.get_damage())

func get_skill_name() -> String:
	return "Drain Life"

func get_skill_description() -> String:
	return "Steal " + str(damage_mult) + " times your base damage in health from a character."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/drain_life.png") # Placeholder path

func get_skill_range() -> int:
	return 3

func target_allies() -> bool:
	return true

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false

func is_melee() -> bool:
	return false

func highlight_targets(_from: CombatCharacter, _map: CombatMap) -> Array[Vector2i]:
	# Identical highlighting logic to FiresparkMage/Frostbolt
	return []

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	curr_highlighted_cells = HexHelper.fov(map.get_cell_coords(from.global_position), mouse_pos, map.can_walk) 
	for cell in curr_highlighted_cells: 
		if HexHelper.distance(map.get_cell_coords(from.global_position), cell) > get_skill_range():
			curr_highlighted_cells.erase(cell)
			continue
		var cell_char = map.get_character(cell)
		if cell_char and cell_char is CombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
		else :
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		

	return curr_highlighted_cells
