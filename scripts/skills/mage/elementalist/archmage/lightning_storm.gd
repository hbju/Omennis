extends Skill
class_name LightningStorm

var damage_mult := 3
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
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true).filter(map.can_walk)

	if not skill_pos in aoe_cells:
		return false # Skill position is not in the AoE radius

	# Find potential targets in radius
	var potential_targets: Array[CombatCharacter] = []
	for cell in aoe_cells:
		var character = map.get_character(cell)
		if is_valid_target_type(from, character):
			potential_targets.append(character)

	print("Potential targets: ", potential_targets)

	if potential_targets.is_empty():
		return false # No enemies in range

	# Select targets randomly
	potential_targets.shuffle()
	var actual_targets = potential_targets.slice(0, num_targets)
	print("Actual targets: ", actual_targets)

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

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:

	var score = AIScoringWeights.WEIGHT_BASE_RANGED
	# Find ALL potential enemies in range

	if potential_targets.is_empty():
		return 0.0 # No enemies in range

	var three_combinations: Array = []
	if potential_targets.size() <= 3:
		three_combinations = [potential_targets]

	else :
		three_combinations = []
		for i in range(potential_targets.size() - 2):
			for j in range(i + 1, potential_targets.size()):
				for k in range(j + 1, potential_targets.size()):
					three_combinations.append([potential_targets[i], potential_targets[j], potential_targets[k]])


	var potential_damage_per_target = from.get_damage() * damage_mult

	var combi_score = 0.0
	
	for combination in three_combinations:
		var total_damage = potential_damage_per_target * combination.size()
		combi_score += total_damage * AIScoringWeights.WEIGHT_DAMAGE * AIScoringWeights.WEIGHT_AOE_TARGET_ENEMY

		for target in combination:
			if target.health <= potential_damage_per_target:
				combi_score += AIScoringWeights.WEIGHT_KILL_BONUS
			else:
				combi_score += (1.0 - (target.health / target.max_health)) * potential_damage_per_target * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
		
			combi_score += AIScoringWeights.WEIGHT_DISABLE_TURN * stun_duration * stun_chance * combination.size()

			combi_score -= target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY #

	score += combi_score / (three_combinations.size() * 1.0) # Average score for all combinations
	

	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var caster_pos = map.get_cell_coords(from.global_position)
	var potential_enemies: Array[CombatCharacter] = []
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in aoe_cells:
		var target_char = map.get_character(cell)
		if target_char and is_valid_target_type(from, target_char): # Check if it's an enemy
			potential_enemies.append(target_char)

	if not potential_enemies.is_empty():
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_AOE_ACTIVATION,
			from,
			caster_pos,
			potential_enemies # List of potential targets
		)]
	else:
		return []



func _apply_effect(target):
	if is_instance_valid(target):
		caster.deal_damage(target, damage_mult)
		if randf() < stun_chance:
			target.gain_status("stunned", stun_duration)

	if curr_storms.has(target):
		var curr_storm = curr_storms[target]
		if is_instance_valid(curr_storm):
			curr_storm.queue_free()
			curr_storms.erase(target)
			
	skill_finished.emit()

func get_skill_name() -> String:
	return "Lightning Storm"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to " + str(num_targets) + " random enemies, with a " + str(int(stun_chance * 100)) + "% chance to stun them.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/lightning_storm.png") 

func get_skill_range() -> int:
	# This is the radius of effect
	return 3

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false 

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