extends Skill
class_name DarkPact

var damage_mult := 4
var health_cost_percent := 0.10
var max_cooldown := 1

const dark_pact_projectile = preload("res://scenes/projectile_effect.tscn")
var curr_projectile: ProjectileEffect
var caster: CombatCharacter
var target: CombatCharacter
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not skill_target or not skill_target is AICombatCharacter or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	# Sacrifice health first
	var health_cost = from.max_health * health_cost_percent
	from.spend_health(health_cost) 

	curr_projectile = dark_pact_projectile.instantiate()
	from.get_parent().add_child(curr_projectile)
	curr_projectile.position = from.position
	curr_projectile.scale = Vector2(1.5, 1.5)
	curr_projectile.speed = 1000.0
	curr_projectile.set_target_position(target.position)
	curr_projectile.target_reached.connect(_on_reached_target, CONNECT_ONE_SHOT)

	cooldown = max_cooldown
	return true

func _on_reached_target():
	if is_instance_valid(target):
		_apply_effect()
	if is_instance_valid(curr_projectile):
		curr_projectile.queue_free()
	skill_finished.emit()

func _apply_effect():
	if is_instance_valid(target):
		caster.deal_damage(target, damage_mult)

func get_skill_name() -> String:
	return "Dark Pact"

func get_skill_description() -> String:
	return "Sacrifice " + str(int(health_cost_percent * 100)) + "% of your max health to deal " + str(damage_mult) + " times your base damage to an enemy."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/dark_pact.png") # Placeholder path

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
	# Identical highlighting logic to FiresparkMage/Frostbolt
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