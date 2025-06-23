# eagle_eye.gd
extends Skill
class_name ShooterStance

var max_cooldown: int = 5
var crit_bonus: float = 0.20 # 20%

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not is_valid_target_type(from, skill_target):
		return false


	from.gain_status("lynx_eye", 99, crit_bonus) # Duration is effectively infinite until moved
	from.character_moved.connect(func () : 
		from.char_statuses["lynx_eye"][0] = 0
		from.char_statuses["lynx_eye"][1] = 0)

	cooldown = max_cooldown
	skill_finished.emit()
	return true

func score_action(from: CombatCharacter, _potential_targets: Array[CombatCharacter], _target_cell: Vector2i, map: CombatMap) -> float:
	var score = AIScoringWeights.WEIGHT_BUFF_POSITIVE * 1.2

	# More valuable if the character is in a safe, advantageous position already.
	var enemies_nearby = 0
	var caster_pos = map.get_cell_coords(from.global_position)
	for p in map.get_alive_party_members():
		if HexHelper.distance(caster_pos, map.get_cell_coords(p.global_position)) <= 3:
			enemies_nearby += 1
	if enemies_nearby == 0:
		score += 15.0 # High bonus for being in a safe sniper nest

	# Less valuable if already has the buff.
	if from.char_statuses["lynx_eye"] > 0:
		score *= 0.1

	return score

func generate_targets(caster: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-cast only
	if is_valid_target_type(caster, caster):
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_CAST, caster, map.get_cell_coords(caster.global_position), [caster]
		)]
	return []

# --- Metadata and UI Functions ---
func get_skill_name() -> String: return "Shooter Stance"
func get_skill_description() -> String:
	return "Enter a state of heightened focus, gaining +%d%% critical hit chance. This effect is lost if you move from your current tile.\nCooldown: %d turns." % [crit_bonus * 100, max_cooldown]
func get_skill_icon() -> Texture: return load("res://assets/ui/skills/shooter_stance.png") # Placeholder
func get_skill_range() -> int: return 0
func is_melee() -> bool: return true # Consistent with self-buffs
func target_allies() -> bool: return false
func target_enemies() -> bool: return false
func target_self() -> bool: return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var cell = map.get_cell_coords(from.global_position)
	map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
	return [cell]

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	if mouse_pos == caster_pos:
		map.set_cell(0, caster_pos, 22, map.get_cell_atlas_coords(0, caster_pos), 8)
	else:
		map.set_cell(0, caster_pos, 22, map.get_cell_atlas_coords(0, caster_pos), 7)
	return [caster_pos]