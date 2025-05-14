extends Skill
class_name FiresparkMage

var damage_mult : float = 1.0
var max_cooldown : int = 1

const firespark_scene = preload("res://scenes/projectile_effect.tscn")
var caster: CombatCharacter
var target: CombatCharacter
var curr_firespark: ProjectileEffect

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target

	curr_firespark = firespark_scene.instantiate()
	from.get_parent().add_child(curr_firespark)
	curr_firespark.position = from.position
	curr_firespark.scale = Vector2(1.5, 1.5)
	curr_firespark.speed = 1500.0
	curr_firespark.set_target_position(target.position)
	curr_firespark.target_reached.connect(_on_reached_target)

	cooldown = max_cooldown
	return true

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], target_cell: Vector2i, map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var curr_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_RANGED # Ranged attacks are generally safer/valuable
	var potential_damage = from.get_damage() * damage_mult
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE

	if curr_target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	else:
		score += (1.0 - (curr_target.health / curr_target.max_health)) * potential_damage * AIScoringWeights.WEIGHT_DAMAGE_PER_HP

	score -= curr_target.shield * AIScoringWeights.WEIGHT_SHIELD_ENEMY

	# Bonus for range - less valuable if target is already close?
	var dist = HexHelper.distance(map.get_cell_coords(from.global_position), target_cell)
	if dist > 1:
		score += dist * AIScoringWeights.WEIGHT_SKILL_DISTANCE # Slight preference for using range

	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(from.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
		if cell != caster_pos:
			var target_char = map.get_character(cell)
			if target_char and is_valid_target_type(from, target_char):
				targets.append(TargetInfo.new(
					TargetInfo.TargetType.CHARACTER,
					target_char,
					cell,
					[target_char]
				))
	return targets

	
func get_skill_name() -> String:
	return "Firespark"

func get_skill_description() -> String:
	return "A basic fire attack that deals " + str(damage_mult) + " times your base damage to an enemy.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n" 

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/firespark.png")

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

func _on_reached_target(): 
	caster.deal_damage(target, damage_mult)
	curr_firespark.queue_free()
	skill_finished.emit()

func highlight_targets(_from: CombatCharacter, _map: CombatMap) -> Array[Vector2i]:
	return []

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var curr_highlighted_cells = HexHelper.fov(map.get_cell_coords(from.global_position), mouse_pos, map.can_walk) 
	for cell in curr_highlighted_cells: 
		if HexHelper.distance(map.get_cell_coords(from.global_position), cell) > get_skill_range():
			curr_highlighted_cells.erase(cell)
			continue
		if cell == mouse_pos and is_valid_target_type(from, map.get_character(cell)):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
		else:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		

	return curr_highlighted_cells
