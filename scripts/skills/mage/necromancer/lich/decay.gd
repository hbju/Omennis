extends Skill
class_name Decay

var damage_percent := 10
var duration := 3
var max_cooldown := 1

const decay_projectile = preload("res://scenes/projectile_effect.tscn") # ASSUMPTION: Visual effect
var caster: CombatCharacter
var target: CombatCharacter
var curr_projectile: Node2D
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not skill_target or not skill_target is AICombatCharacter or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	# Launch visual effect
	curr_projectile = decay_projectile.instantiate()
	from.get_parent().add_child(curr_projectile)
	curr_projectile.position = from.position
	curr_projectile.set_target_position(target.position)
	curr_projectile.target_reached.connect(_on_reached_target, CONNECT_ONE_SHOT)


	cooldown = max_cooldown
	# Don't emit finished yet
	return true

func _on_reached_target():
	if is_instance_valid(target):
		target.gain_decay_status(duration, damage_percent)
	if is_instance_valid(curr_projectile):
		curr_projectile.queue_free()
	skill_finished.emit()


func get_skill_name() -> String:
	return "Decay"

func get_skill_description() -> String:
	return "Inflict a decay effect on the enemy, causing them to lose " + str(int(damage_percent)) + "% of their max health at the end of their turn for " + str(duration) + " turns. \nStacks."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/decay.png") # Placeholder path

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
