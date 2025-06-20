# mark_target.gd
extends Skill
class_name MarkTarget

var max_cooldown: int = 5
var duration: int = 3
var damage_increase: float = 0.5 # 50%

const mark_impact_scene = preload("res://scenes/impact_effect.tscn")
var caster: CombatCharacter
var target: CombatCharacter
var curr_projectile: ImpactEffect

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target) or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
		return false
	

	caster = from
	target = skill_target
	
	curr_projectile = mark_impact_scene.instantiate()
	from.get_parent().add_child(curr_projectile)
	curr_projectile.position = skill_pos
	curr_projectile.set_impact_type("thunderstrike")
	curr_projectile.animated_sprite.animation_looped.connect(_apply_effect)

	cooldown = max_cooldown
	return true

func _apply_effect():
	if is_instance_valid(target):
		target.gain_status("vulnerable", duration)
		if not target.character_died.is_connected(_on_marked_target_died):
			target.character_died.connect(_on_marked_target_died)
	
	if is_instance_valid(curr_projectile):
		curr_projectile.queue_free()
		
	skill_finished.emit()

func _on_marked_target_died(dead_character: CombatCharacter):
	if is_instance_valid(dead_character) and dead_character.character_died.is_connected(_on_marked_target_died):
		dead_character.character_died.disconnect(_on_marked_target_died)
		
	if dead_character != target : 
		return
	cooldown = 0

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	if potential_targets.is_empty(): return 0.0
	var potential_target = potential_targets[0]

	var score = AIScoringWeights.WEIGHT_SETUP_BONUS * 1.5 # High value setup skill

	# More valuable on high-health targets that the party needs to focus down.
	score += (potential_target.health / potential_target.max_health) * 20.0

	# Less valuable if target is already vulnerable.
	if potential_target.char_statuses["vulnerable"] > 0:
		score *= 0.1

	# More valuable if other allies are in a position to attack the target.
	var allies_can_attack = 0
	for ally in map.characters:
		if ally is AICombatCharacter and ally != from:
			if HexHelper.distance(map.get_cell_coords(ally.global_position), map.get_cell_coords(potential_target.global_position)) <= 4: # Simple range check
				allies_can_attack += 1
	score += allies_can_attack * 10.0

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
func get_skill_name() -> String: return "Mark Target"
func get_skill_description() -> String:
	return "Mark an enemy, increasing damage they take from all sources by %d%% for %d turns. Killing the marked enemy resets this skill's cooldown.\nCooldown: %d turns." % [damage_increase * 100, duration, max_cooldown]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/mark_target.png") # Placeholder path
func get_skill_range() -> int: return 3
func is_melee() -> bool: return false
func target_allies() -> bool: return false
func target_enemies() -> bool: return true
func target_self() -> bool: return false

func highlight_targets(_from: CombatCharacter, _map: CombatMap) -> Array[Vector2i]:
	return [] # Standard ranged skill, highlighting handled by mouse_pos

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var fov_cells = HexHelper.fov(map.get_cell_coords(from.global_position), mouse_pos, map.can_walk)
	var valid_cells: Array[Vector2i] = []
	
	for cell in fov_cells:
		if HexHelper.distance(map.get_cell_coords(from.global_position), cell) > get_skill_range():
			continue
		
		valid_cells.append(cell)
		var cell_char = map.get_character(cell)
		
		if cell == mouse_pos and is_valid_target_type(from, cell_char):
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5) # Valid hover target
		else:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3) # Path highlight
			
	return valid_cells