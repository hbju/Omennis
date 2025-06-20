# silencing_shot.gd
extends Skill
class_name SilencingShot

var damage_mult: float = 3.0
var silence_duration: int = 2
var max_cooldown: int = 4

const projectile_scene = preload("res://scenes/projectile_effect.tscn")
var caster: CombatCharacter
var target: CombatCharacter
var curr_projectile: ProjectileEffect

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false

	caster = from
	target = skill_target
	
	curr_projectile = projectile_scene.instantiate()
	from.get_parent().add_child(curr_projectile)
	curr_projectile.position = from.position
	curr_projectile.set_target_position(target.position)
	curr_projectile.target_reached.connect(_on_reached_target, CONNECT_ONE_SHOT)
	
	cooldown = max_cooldown
	return true

func _on_reached_target():
	if is_instance_valid(target) and is_instance_valid(caster):
		caster.deal_damage(target, damage_mult)
		target.gain_status("silence", silence_duration)

	if is_instance_valid(curr_projectile):
		curr_projectile.queue_free()
		
	skill_finished.emit()

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_RANGED
	
	# Score Silence effect - highly valuable control
	score += AIScoringWeights.WEIGHT_DISABLE_TURN * 0.7 * silence_duration # Slightly less than stun, but still very high
	
	# Score damage
	var potential_damage = from.get_damage() * damage_mult
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	
	if potential_target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
		
	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Standard ranged targeting
	var targets: Array[TargetInfo] = []
	var caster_pos = map.get_cell_coords(from.global_position)
	var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)

	for cell in potential_cells:
		if cell != caster_pos:
			var target_char = map.get_character(cell)
			if is_valid_target_type(from, target_char):
				targets.append(TargetInfo.new(
					TargetInfo.TargetType.CHARACTER, target_char, cell, [target_char]
				))
	return targets

# --- Metadata and UI Functions ---
func get_skill_name() -> String: return "Silencing Shot"
func get_skill_description() -> String:
	return "Deal %.1fx base damage and Silence the target for %d turns, preventing them from using skills.\nCooldown: %d turns.\nRange: %d cells." % [damage_mult, silence_duration, max_cooldown, get_skill_range()]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/silencing_shot.png")
func get_skill_range() -> int: return 5
func is_melee() -> bool: return false
func target_allies() -> bool: return false
func target_enemies() -> bool: return true
func target_self() -> bool: return false

func highlight_targets(_from: CombatCharacter, _map: CombatMap) -> Array[Vector2i]:
	return []

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array:
	var fov_cells = HexHelper.fov(map.get_cell_coords(from.global_position), mouse_pos, map.can_walk)
	var valid_cells: Array[Vector2i] = []
	for cell in fov_cells:
		if HexHelper.distance(map.get_cell_coords(from.global_position), cell) > get_skill_range():
			continue
		valid_cells.append(cell)
		var cell_char = map.get_character(cell)
		if cell == mouse_pos and is_valid_target_type(from, cell_char):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
		else:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
	return valid_cells