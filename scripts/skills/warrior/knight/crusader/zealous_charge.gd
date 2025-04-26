extends Skill
class_name ZealousCharge

var damage_mult := 3
var knockback_distance := 1
var knockback_damage_mult := 1
var stunned_duration := 1
var max_cooldown := 3
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) <= get_skill_range():
		return false

	from.attack(map.to_local(skill_target.global_position))
	from.deal_damage(skill_target, damage_mult)
	skill_target.gain_status("stunned", stunned_duration)
	skill_target.knockback(knockback_distance, _get_knockback_dir(from, skill_target, map), knockback_damage_mult * from.get_damage())
	cooldown = max_cooldown
	return true

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], target_cell: Vector2i, map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_RANGED # Movement + Damage + Stun + Knockback
	var potential_damage = from.get_damage() * damage_mult

	# Score damage
	var damage_score = potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	if potential_target.health <= potential_damage:
		damage_score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		damage_score += (1.0 - (potential_target.health / potential_target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
	damage_score -= potential_target.shield * 0.1

	# Score stun
	var stun_score = AIScoringWeights.WEIGHT_DISABLE_TURN

	# Score knockback - value based on potential collision or moving target away
	var knockback_score = 5.0 # Base value for displacement
	var knock_dir = _get_knockback_dir(from, potential_target, map)
	if knock_dir != -1:
		var final_kb_pos = target_cell
		var collision = false
		var collision_damage = 0.0
		for i in range(knockback_distance):
			var next_pos = HexHelper.hex_neighbor(final_kb_pos, knock_dir)
			if not map.can_walk(next_pos) or map.cell_occupied(next_pos):
				collision = true
				# Add potential collision damage score
				collision_damage = from.get_damage() * knockback_damage_mult
				knockback_score += collision_damage * AIScoringWeights.WEIGHT_DAMAGE * 0.8 # Collision damage is bonus
				break
			final_kb_pos = next_pos
		if collision:
			knockback_score += 10.0 # Bonus for causing collision

	# Score movement aspect (less than pure Charge as CC is primary)
	score += HexHelper.distance(map.get_cell_coords(from.global_position), target_cell) * AIScoringWeights.WEIGHT_POSITIONING_CLOSER * 0.3

	score += damage_score + stun_score + knockback_score
	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(caster.global_position)

	for i in range(6): # Check all 6 directions
		var current_cell = caster_pos
		for j in range(1, get_skill_range() + 1): # Check cells along the path
			current_cell = HexHelper.hex_neighbor(current_cell, i)
			if not map.can_walk(current_cell):
				break 

			# If we reached the target distance
			var target_char = map.get_character(current_cell)
			if is_valid_target_type(caster, target_char):
				# Found a valid target at the correct distance
				targets.append(TargetInfo.new(
					TargetInfo.TargetType.CHARACTER, target_char, current_cell, [target_char]
				))
				# Stop checking this column after reaching the target distance
				break
		# Loop continues to next direction if path wasn't clear or no target at dist
	return targets

	
func get_skill_name() -> String:
	return "Zealous Charge"

func get_skill_description() -> String:
	return "Charge a target from " + str(get_skill_range()) + " tiles away, dealing " + str(damage_mult) + " times your base damage, stunning them for one turn and knocking them back one tile.\n" + \
		"Can only target enemies not adjacent to you, in a straight line.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/zealous_charge.png")

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

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	curr_highlighted_cells = map.highlight_columns(map.get_cell_coords(from.global_position), get_skill_range())
	return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, _mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	return highlight_targets(from, map)

func _get_knockback_dir(from: CombatCharacter, target: CombatCharacter, map: CombatMap) -> int:
	var cube_coords_from = HexHelper.axial_to_cube(HexHelper.oddr_to_axial(map.get_cell_coords(from.global_position)))
	var cube_coords_target = HexHelper.axial_to_cube(HexHelper.oddr_to_axial(map.get_cell_coords(target.global_position)))

	if cube_coords_from.x == cube_coords_target.x:
		if cube_coords_from.y < cube_coords_target.y:
			return 5
		else:
			return 2
	if cube_coords_from.y == cube_coords_target.y:
		if cube_coords_from.x < cube_coords_target.x:
			return 0
		else:
			return 3
	if cube_coords_from.z == cube_coords_target.z:
		if cube_coords_from.x < cube_coords_target.x:
			return 1
		else:
			return 4

	return -1