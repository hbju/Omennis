# shadow_strike.gd
extends Skill
class_name ShadowStrike

var damage_mult: float = 3.0
var stealth_duration: int = 2
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
		caster.gain_status("stealth", stealth_duration + 1) # +1 to last through next turn start

	if is_instance_valid(curr_projectile):
		curr_projectile.queue_free()
		
	skill_finished.emit()

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_BASE_RANGED
	
	# Score Damage
	var potential_damage = from.get_damage() * damage_mult
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	
	if potential_target.health <= potential_damage:
		score += AIScoringWeights.WEIGHT_KILL_BONUS
	
	# Score Stealth Gain (very valuable)
	score += AIScoringWeights.WEIGHT_BUFF_POSITIVE * 1.8 # Gaining stealth is a powerful defensive move.
	
	# Higher value if used to escape a dangerous position
	var enemies_near_caster = 0
	for p in _map.get_alive_party_members():
		if HexHelper.distance(_map.get_cell_coords(from.global_position), _map.get_cell_coords(p.global_position)) <= 2:
			enemies_near_caster += 1
	score += enemies_near_caster * 8.0 # Bonus for each nearby enemy to incentivize escaping

	return score

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
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
func get_skill_name() -> String: return "Shadow Strike"
func get_skill_description() -> String:
	return "Deal %.1fx your base damage to an enemy and enter Stealth for %d turns.\nCooldown: %d turns.\nRange: %d cells." % [damage_mult, stealth_duration, max_cooldown, get_skill_range()]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/shadow_strike.png") # Placeholder
func get_skill_range() -> int: return 2
func is_melee() -> bool: return false
func target_allies() -> bool: return false
func target_enemies() -> bool: return true
func target_self() -> bool: return false

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	var valid_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), map.can_walk)
	valid_cells.erase(caster_pos)
	for cell in valid_cells:
		var potential_target = map.get_character(cell)
		if is_valid_target_type(from, potential_target):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4) # Mark as targetable
	return valid_cells

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var valid_cells = highlight_targets(from, map)
	if mouse_pos in valid_cells and is_valid_target_type(from, map.get_character(mouse_pos)):
		map.set_cell(0, mouse_pos, 22, map.get_cell_atlas_coords(0, mouse_pos), 5) # Mark as hovered
	return valid_cells