extends Skill
class_name DeathCoil

var damage_mult := 3
var heal_percent := 0.5
var max_cooldown := 2

const death_coil_projectile = preload("res://scenes/projectile_effect.tscn") 
var caster: CombatCharacter
var target: CombatCharacter
var curr_projectile: ProjectileEffect
var curr_highlighted_cells: Array[Vector2i] = []
var duration := 2 

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	curr_projectile = death_coil_projectile.instantiate()
	from.get_parent().add_child(curr_projectile)
	curr_projectile.position = from.position
	curr_projectile.set_target_position(target.position)
	curr_projectile.target_reached.connect(_on_reached_target, CONNECT_ONE_SHOT)


	cooldown = max_cooldown
	return true

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_RANGED 
	var potential_damage = from.get_damage() * damage_mult
	var potential_heal = potential_damage * heal_percent

	# Score damage
	var damage_score = potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	if potential_target.health <= potential_damage:
		damage_score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		damage_score += (1.0 - (potential_target.health / potential_target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
	damage_score -= potential_target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY

	# Score heal
	var heal_score = potential_heal * AIScoringWeights.WEIGHT_HEAL
	heal_score += (1.0 - (from.health / from.max_health)) * potential_heal * AIScoringWeights.WEIGHT_HEAL_LOW_HP_BONUS

	# Score debuff (Weak)
	var debuff_score = AIScoringWeights.WEIGHT_BUFF_NEGATIVE * duration
	if potential_target.char_statuses["strong"] > 0:
		debuff_score *= 1.2

	score += damage_score + heal_score + debuff_score
	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Ranged single target enemy
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(from.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func (_hex) : return true)

	for cell in potential_cells:
		var target_char = map.get_character(cell)
		if is_valid_target_type(from, target_char): # Checks target_enemies flag
			targets.append(TargetInfo.new(
				TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
			))
	return targets


func _on_reached_target():
	if is_instance_valid(target) and is_instance_valid(caster):
		var damage = caster.deal_damage(target, damage_mult)
		caster.heal(damage * heal_percent)
		target.gain_status("weak", duration + 1)
	if is_instance_valid(curr_projectile):
		curr_projectile.queue_free()
	skill_finished.emit()


func get_skill_name() -> String:
	return "Death Coil"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to an enemy and heal yourself for " + str(int(heal_percent * 100)) + "% of the damage dealt. Reduces the target's damage by 33% for " + str(duration) + " turns.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/death_coil.png") 

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
		if cell_char and cell_char is CombatCharacter:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
		else :
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		

	return curr_highlighted_cells
