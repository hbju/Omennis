extends Skill
class_name Meteor

var total_damage_mult := 10
var aoe_radius := 1
var max_cooldown := 5

const meteor_scene = preload("res://scenes/impact_effect.tscn")
var curr_meteor: ImpactEffect 
var targets: Array[CombatCharacter] = []
var caster: CombatCharacter
var curr_highlighted_cells: Array[Vector2i] = []


func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	caster = from
	targets = []
	var caster_pos = map.get_cell_coords(from.global_position)
	if HexHelper.distance(caster_pos, skill_pos) > get_skill_range():
		return false

	# Find all characters in the AoE centered on skill_pos
	var impact_cells = HexHelper.hex_reachable(skill_pos, aoe_radius, func(_hex): return true)
	for cell in impact_cells:
		var character = map.get_character(cell)
		if character:
			targets.append(character)

	if targets.is_empty():
		return false

	# Play visual effect at skill_pos
	curr_meteor = meteor_scene.instantiate()
	map.add_child(curr_meteor) 
	curr_meteor.position = map.map_to_local(skill_pos)
	curr_meteor.scale = Vector2(6, 6)
	curr_meteor.set_impact_type("thunderstrike")
	curr_meteor.animated_sprite.animation_looped.connect(_apply_effect)

	cooldown = max_cooldown
	return true

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	# potential_targets here are ALL characters in the AoE of target_cell
	if potential_targets.is_empty(): return 0.0

	var score = AIScoringWeights.WEIGHT_BASE_RANGED
	var damage_per_target = (from.get_damage() * total_damage_mult) / potential_targets.size()

	var enemy_targets = 0
	var total_enemy_damage_score = 0.0
	var total_ally_damage_penalty = 0.0

	for target in potential_targets:
		if target is PlayerCombatCharacter: # Is Enemy?
			enemy_targets += 1
			var enemy_score = damage_per_target * AIScoringWeights.WEIGHT_DAMAGE
			if target.health <= damage_per_target:
				enemy_score += AIScoringWeights.WEIGHT_KILL_BONUS
			else:
				enemy_score += (1.0 - (target.health / target.max_health)) * damage_per_target * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
			total_enemy_damage_score += enemy_score
		else :
			# Apply penalty for hitting allies
			total_ally_damage_penalty += AIScoringWeights.WEIGHT_AOE_TARGET_ALLY_DAMAGE_PENALTY * (damage_per_target / target.max_health) # Penalty scaled by % max hp damage

	if enemy_targets == 0: return 0.0 # No enemies in AoE

	score += total_enemy_damage_score * AIScoringWeights.WEIGHT_AOE_TARGET_ENEMY
	score += total_ally_damage_penalty # Penalty is negative

	return max(0.0, score) 

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var potential_targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(from.global_position)
	# Find all valid center points within skill range
	var potential_center_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func (_hex): return true).filter(map.can_walk)

	for center_cell in potential_center_cells:
		# For each center, calculate who would be hit
		var impact_cells = HexHelper.hex_reachable(center_cell, aoe_radius, func(_hex): return true)
		var characters_hit: Array[CombatCharacter] = []
		for cell in impact_cells:
			var character = map.get_character(cell)
			if is_valid_target_type(from, character):
				characters_hit.append(character)

		# Only create a TargetInfo if this location actually hits someone
		if not characters_hit.is_empty():
			potential_targets.append(TargetInfo.new(
				TargetInfo.TargetType.AOE_LOCATION,
				null,          # No single primary target
				center_cell,   # The center of the blast
				characters_hit # All characters hit by aiming here
			))
	return potential_targets


func _apply_effect(): 
	var damage_mult = total_damage_mult / (len(targets)*1.0)
	for target in targets : 
		caster.deal_damage(target, damage_mult)
	curr_meteor.queue_free()
	skill_finished.emit()

func get_skill_name() -> String:
	return "Meteor"

func get_skill_description() -> String:
	return "Deal " + str(total_damage_mult) + " times your base damage divided between all characters in a " + str(aoe_radius) + "-cell radius around the target location.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/meteor.png") 

func get_skill_range() -> int:
	return 4

func target_allies() -> bool:
	return true # Can hit allies in blast

func target_enemies() -> bool:
	return true # Can hit enemies in blast

func target_self() -> bool:
	return true # Can hit self if targeted nearby

func is_melee() -> bool:
	return false

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex: Vector2i): return true).filter(func (cell): return map.can_walk((cell)))

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)

	return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	map.reset_map()
	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)

	# If mouse is over a valid center point, highlight the AoE
	if mouse_pos in curr_highlighted_cells:
		map.set_cell(0, mouse_pos, 22, map.get_cell_atlas_coords(0, mouse_pos), 4) # Hovered target cell
		var curr_aoe_highlight = HexHelper.hex_reachable(mouse_pos, aoe_radius, func(hex): return map.can_walk(hex))

		for cell in curr_aoe_highlight:
			var character = map.get_character(cell)
			if character:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
			else:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)

	return curr_highlighted_cells # Return the valid center points