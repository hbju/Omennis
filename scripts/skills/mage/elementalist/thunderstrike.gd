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
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
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

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], target_cell: Vector2i, map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = 10.0
	var potential_damage = from.get_damage() * damage_mult
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE

	if potential_target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		score += (1.0 - (potential_target.health / potential_target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP

	# Significant bonus for the stun effect
	score += AIScoringWeights.WEIGHT_DISABLE_TURN * stun_duration

	score -= potential_target.shield * 0.1
	var dist = HexHelper.distance(map.get_cell_coords(from.global_position), target_cell)
	if dist > 1: score += dist * 1.0

	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Identical logic to Firespark/Frostbolt
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(from.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
		if cell != caster_pos:
			var target_char = map.get_character(cell)
			if target_char and is_valid_target_type(from, target_char):
				targets.append(TargetInfo.new(
					TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
				))
	return targets

func _apply_effect():
	if is_instance_valid(target):
		caster.deal_damage(target, damage_mult)
		target.gain_status("stunned", stun_duration)

	skill_finished.emit()
	curr_thunderstrike.queue_free()

func get_skill_name() -> String:
	return "Thunderstrike"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to a single enemy and stun them for " + str(stun_duration) + " turn.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells."

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
