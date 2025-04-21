extends Skill
class_name Firespark

var damage_mult : int = 2
var max_cooldown : int = 2

const firespark_scene = preload("res://scenes/projectile_effect.tscn")
var caster: CombatCharacter
var target: CombatCharacter
var curr_firespark: ProjectileEffect
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not skill_target or not skill_target is AICombatCharacter or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	curr_firespark = firespark_scene.instantiate()
	from.get_parent().add_child(curr_firespark)
	curr_firespark.scale = Vector2(1.5, 1.5) 
	curr_firespark.speed = 1500.0
	curr_firespark.position = from.position
	curr_firespark.set_target_position(target.position)
	curr_firespark.target_reached.connect(_on_reached_target)

	cooldown = max_cooldown
	return true
	
func get_skill_name() -> String:
	return "Firespark"

func get_skill_description() -> String:
	return "A basic fire attack that deals 90 damage to a ranged enemy."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/firespark.png")

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

func _on_reached_target(): 
	target.take_damage(damage_mult * caster.get_damage())
	curr_firespark.queue_free()
	skill_finished.emit()

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
