extends Skill
class_name Thunderstrike

var damage_mult := 3
var stun_duration := 1
var max_cooldown := 5

const thunderstrike_scene = preload("res://scenes/impact_effect.tscn")
var caster: CombatCharacter
var target: CombatCharacter
var curr_thunderstrike: ImpactEffect
var curr_highlighted_cells: Array[Vector2i] = []


func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not skill_target or not skill_target is AICombatCharacter or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	curr_thunderstrike = thunderstrike_scene.instantiate()
	curr_thunderstrike.position = target.position
	target.get_parent().add_child(curr_thunderstrike)
	curr_thunderstrike.scale = Vector2(1.5, 1.5)
	curr_thunderstrike.set_impact_type("thunderstrike")

	curr_thunderstrike.animated_sprite.animation_looped.connect(_apply_effect)

	cooldown = max_cooldown
	return true

func _apply_effect():
	if is_instance_valid(target):
		caster.deal_damage(target, damage_mult)
		target.gain_stunned_status(stun_duration)

	skill_finished.emit()
	curr_thunderstrike.queue_free()

func get_skill_name() -> String:
	return "Thunderstrike"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to a single enemy and stun them for " + str(stun_duration) + " turn."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/thunderstrike.png") # Placeholder path

func get_skill_range() -> int:
	return 3

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
	# Identical highlighting logic to FiresparkMage/Frostbolt
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
