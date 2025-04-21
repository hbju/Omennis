extends Skill
class_name LightningStorm

var damage_mult := 4
var num_targets := 3
var stun_chance := 0.5
var stun_duration := 1
var max_cooldown := 6
var curr_highlighted_cells: Array[Vector2i] = []


const thunderstrike_scene = preload("res://scenes/impact_effect.tscn") 
var caster: CombatCharacter
var curr_storms: Dictionary = {} 



func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(from.global_position)
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true)

	if not skill_pos in aoe_cells:
		return false # Skill position is not in the AoE radius

	# Find potential targets in radius
	var potential_targets: Array[AICombatCharacter] = []
	for cell in aoe_cells:
		var character = map.get_character(cell)
		if character and character is AICombatCharacter:
			potential_targets.append(character)


	if potential_targets.is_empty():
		return false # No enemies in range

	# Select targets randomly
	potential_targets.shuffle()
	var actual_targets = potential_targets.slice(0, min(num_targets, potential_targets.size()))

	caster = from

	for target in actual_targets:
		var curr_storm = thunderstrike_scene.instantiate()
		curr_storm.position = target.position
		target.get_parent().add_child(curr_storm)
		curr_storm.scale = Vector2(2.5, 2.5)
		curr_storm.set_impact_type("lightning_storm")
		curr_storm.animated_sprite.animation_looped.connect(_apply_effect.bind(target))
		curr_storms[target] = curr_storm 

	cooldown = max_cooldown
	return true


func _apply_effect(target):
	if is_instance_valid(target):
		caster.deal_damage(target, damage_mult)
		if randf() < stun_chance:
			target.gain_stunned_status(stun_duration)

	# Remove the storm effect
	if curr_storms.has(target):
		var curr_storm = curr_storms[target]
		if is_instance_valid(curr_storm):
			curr_storm.queue_free()
			curr_storms.erase(target)
			
	skill_finished.emit()

func get_skill_name() -> String:
	return "Lightning Storm"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to " + str(num_targets) + " random enemies within a " + str(get_skill_range()) + "-cell radius, with a " + str(int(stun_chance * 100)) + "% chance to stun them."

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/lightning_storm.png") # Placeholder path

func get_skill_range() -> int:
	# This is the radius of effect
	return 3

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true # Implicitly targets enemies in area

func target_self() -> bool:
	return true # Activated by targeting self / area around self

func is_melee() -> bool:
	# Consistent with Whirlwind/Inquisition (AoE centered on self)
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func (_hex): return true).filter(func (cell): return map.can_walk((cell)))

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 1) # Highlight area tile
		var character = map.get_character(cell)
		if character and character is AICombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3) # Mark enemy in area
		elif character and character is PlayerCombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 0)

	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var highlight_color = 1
	if mouse_pos in curr_highlighted_cells:
		highlight_color = 2

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), highlight_color)
		var character = map.get_character(cell)

		if character:
			var char_highlight = 0
			var char_hover_highlight = 0
			if character is AICombatCharacter:
				char_highlight = 3; char_hover_highlight = 5

			if mouse_pos in curr_highlighted_cells:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), char_hover_highlight)
			else: # Mouse outside AoE, just show characters normally within AoE
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), char_highlight)

	return curr_highlighted_cells