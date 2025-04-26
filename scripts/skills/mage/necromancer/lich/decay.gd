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
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
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

func score_action(_from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BUFF_NEGATIVE * 0.8 # DoT is generally less immediate value than debuffs

	# Calculate total potential damage over duration
	var damage_per_turn = potential_target.max_health * damage_percent / 100.0
	var total_dot_damage = damage_per_turn * duration

	# Score based on total damage, but discount it compared to direct damage
	score += total_dot_damage * AIScoringWeights.WEIGHT_DAMAGE * 0.5

	# Bonus if target is high health (DoT %HP is better)
	score += (potential_target.health / potential_target.max_health) * 10.0

	# Bonus if target doesn't already have decay or has fewer stacks
	var current_decay_stacks = potential_target.char_statuses["decay"][0] # Duration acts as proxy for stacks here
	var current_decay_percent = potential_target.char_statuses["decay"][1]
	# Value applying the *first* stack more, or refreshing a long duration one
	if current_decay_stacks < duration:
		score += 3.0 * (duration - current_decay_stacks) 
	# Value adding to existing stacks, up to a point
	score += (damage_percent / max(10.0, current_decay_percent)) * 10.0 # Diminishing returns as % increases

	# Consider if target might die before DoT finishes? Hard to predict.

	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Ranged single target enemy
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(from.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(from, target_char):
			targets.append(TargetInfo.new(
				TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
			))
	return targets

func _on_reached_target():
	if is_instance_valid(target):
		target.gain_status("decay", duration, damage_percent)
	if is_instance_valid(curr_projectile):
		curr_projectile.queue_free()
	skill_finished.emit()


func get_skill_name() -> String:
	return "Decay"

func get_skill_description() -> String:
	return "Inflict a decay effect on the enemy, causing them to lose " + str(int(damage_percent)) + "% of their max health at the end of their turn for " + str(duration) + " turns. \nStacks.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n" 

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
