extends Skill
class_name SoulHarvest

const harvest_effect = preload("res://scenes/impact_effect.tscn")
var damage_mult := 3
var max_cooldown := 3
var curr_highlighted_cells: Array[Vector2i] = []

var targets : Array[CombatCharacter] = []
var caster: CombatCharacter
var curr_effect: ImpactEffect

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(from.global_position) 
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true)

	if not aoe_cells.has(skill_pos):
		return false

	caster = from
	targets = []
	for cell in aoe_cells:
		var character = map.get_character(cell)
		if character and character != from:
			targets.append(character)

	if targets.is_empty():
		return false

	curr_effect = harvest_effect.instantiate()
	from.get_parent().add_child(curr_effect)
	curr_effect.position = from.position
	curr_effect.scale = Vector2(6, 6)
	curr_effect.set_impact_type("thunderstrike")
	curr_effect.animated_sprite.animation_looped.connect(_on_reached_target, CONNECT_ONE_SHOT)

	cooldown = max_cooldown
	return true

func _on_reached_target():
	if is_instance_valid(curr_effect):
		curr_effect.queue_free()

	for target in targets:
		if is_instance_valid(target):
			caster.deal_damage(target, damage_mult)

	skill_finished.emit()

func get_skill_name() -> String:
	return "Soul Harvest"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to all characters in a " + str(get_skill_range()) + "-cell radius."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/soul_harvest.png") # Placeholder path

func get_skill_range() -> int:
	return 2

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true # Implicitly via area

func target_self() -> bool:
	return true # Activation target

func is_melee() -> bool:
	# Consistent with Lightning Storm / Whirlwind
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex: Vector2i): return true).filter(func (cell): return map.can_walk((cell)))

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		var character = map.get_character(cell)
		if character:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)
		if cell == caster_pos:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 0)

	return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var highlight_color = 3
	if mouse_pos in curr_highlighted_cells:
		highlight_color = 4

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), highlight_color)
		var character = map.get_character(cell)
		var caster_pos = map.get_cell_coords(from.global_position)

		if character:
			var char_highlight = 4; var char_hover_highlight = 5
			if cell == caster_pos:
				char_highlight = 0; char_hover_highlight = 0

			if mouse_pos in curr_highlighted_cells:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), char_hover_highlight)
			else:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), char_highlight)

	return curr_highlighted_cells
