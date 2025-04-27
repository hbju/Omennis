extends Skill
class_name DrainLife

var damage_mult := 2
var max_cooldown := 4

const drain_life_effect = preload("res://scenes/projectile_effect.tscn") # ASSUMPTION: Beam/effect visual
var caster: CombatCharacter
var target: CombatCharacter
var curr_effect: ProjectileEffect
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	curr_effect = drain_life_effect.instantiate()
	from.get_parent().add_child(curr_effect)
	curr_effect.position = from.position
	curr_effect.scale = Vector2(1.5, 1.5)
	curr_effect.speed = 1000.0
	curr_effect.set_target_position(target.position)
	curr_effect.target_reached.connect(_on_reached_target, CONNECT_ONE_SHOT)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_RANGED
	var potential_damage = from.get_damage() * damage_mult
	var potential_heal = potential_damage # Heal amount equals damage dealt

	# Score damage component
	var damage_score = potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	if potential_target.health <= potential_damage:
		damage_score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		damage_score += (1.0 - (potential_target.health / potential_target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
	damage_score -= potential_target.shield * 0.1

	# Score heal component
	var heal_score = potential_heal * AIScoringWeights.WEIGHT_HEAL
	# Value heal more if caster is low health
	var caster_health_percent = from.health / from.max_health
	heal_score += (1.0 - caster_health_percent) * potential_heal * AIScoringWeights.WEIGHT_HEAL_LOW_HP_BONUS

	# If targeting an ally, damage score is negative!
	if potential_target is AICombatCharacter : 
		damage_score = (1 - (potential_target.health / potential_target.max_health)) * AIScoringWeights.WEIGHT_AOE_TARGET_ALLY_DAMAGE_PENALTY # Use heavy penalty

	score += damage_score + heal_score
	return max(0.0, score)

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Ranged single target, can hit allies or enemies
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
		_apply_effect()
	if is_instance_valid(curr_effect):
		curr_effect.queue_free()

func _apply_effect():
	if is_instance_valid(target) and is_instance_valid(caster):
		caster.deal_damage(target, damage_mult)
		caster.heal(damage_mult * caster.get_damage())

func get_skill_name() -> String:
	return "Drain Life"

func get_skill_description() -> String:
	return "Steal " + str(damage_mult) + " times your base damage in health from a character.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/drain_life.png") 

func get_skill_range() -> int:
	return 3

func target_allies() -> bool:
	return true

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
		if cell_char and cell_char is CombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
		else :
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		

	return curr_highlighted_cells
