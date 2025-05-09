extends Skill
class_name DarkPact

var damage_mult := 3
var health_cost_percent := 0.15
var max_cooldown := 1

const dark_pact_projectile = preload("res://scenes/projectile_effect.tscn")
var curr_projectile: ProjectileEffect
var caster: CombatCharacter
var target: CombatCharacter
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
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

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_RANGED
	var potential_damage = from.get_damage() * damage_mult
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE

	if potential_target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		score += (1.0 - (potential_target.health / potential_target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP

	# Penalty for health cost
	var health_cost = from.max_health * health_cost_percent
	score += health_cost_percent * 100.0 * AIScoringWeights.WEIGHT_HEALTH_COST_PENALTY

	# Heavily penalize if the health cost would kill the caster
	if from.health <= health_cost:
		score = 0.0 # Never suicide with this skill

	# Reduce score significantly if caster health is already low
	if from.health < from.max_health * 0.3:
		score *= 0.25

	score -= potential_target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY

	return max(0.0, score) # Ensure score isn't negative

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(from.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func (_hex): return true).filter(map.can_walk)

	for cell in potential_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(from, target_char):
			targets.append(TargetInfo.new(
				TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
			))
	return targets

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
	return "Sacrifice " + str(int(health_cost_percent * 100)) + "% of your max health to deal " + str(damage_mult) + " times your base damage to an enemy.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/dark_pact.png") 

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