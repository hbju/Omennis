extends Skill
class_name SoulHarvest

const harvest_effect = preload("res://scenes/impact_effect.tscn")
var damage_mult := 4
var max_cooldown := 3
var curr_highlighted_cells: Array[Vector2i] = []

var targets : Array[CombatCharacter] = []
var caster: CombatCharacter
var curr_effect: ImpactEffect

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var caster_pos = map.get_cell_coords(from.global_position) 
	var aoe_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true)

	if not aoe_cells.has(skill_pos):
		return false

	caster = from
	targets = []
	for cell in aoe_cells:
		var character = map.get_character(cell)
		if is_valid_target_type(from, character) :
			targets.append(character)

	if targets.is_empty():
		return false

	curr_effect = harvest_effect.instantiate()
	from.get_parent().add_child(curr_effect)
	curr_effect.position = from.position
	curr_effect.scale = Vector2(6, 6)
	curr_effect.set_impact_type("thunderstrike")
	curr_effect.animated_sprite.animation_looped.connect(_on_reached_target, CONNECT_ONE_SHOT)

	cooldown = max_cooldown
	return true

func score_action(from: CombatCharacter, potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	# AoE Damage around self
	# potential_targets should include all characters hit (excluding self)
	if potential_targets.is_empty(): return 0.0

	var score = AIScoringWeights.WEIGHT_BASE_RANGED # Base for AoE damage
	var potential_damage_per_target = from.get_damage() * damage_mult
	var total_enemy_damage_score = 0.0
	var total_ally_damage_penalty = 0.0
	var enemies_hit = 0

	for target in potential_targets:
		if target == from: continue # Should already be excluded by use_skill logic

		if target is PlayerCombatCharacter: # Is Enemy?
			enemies_hit += 1
			var enemy_score = potential_damage_per_target * AIScoringWeights.WEIGHT_DAMAGE
			if target.health <= potential_damage_per_target:
				enemy_score += AIScoringWeights.WEIGHT_KILL_BONUS
			else:
				enemy_score += (1.0 - (target.health / target.max_health)) * potential_damage_per_target * AIScoringWeights.WEIGHT_DAMAGE_PER_HP
			total_enemy_damage_score += enemy_score
		else: # Is Ally?
			total_ally_damage_penalty += AIScoringWeights.WEIGHT_AOE_TARGET_ALLY_DAMAGE_PENALTY * (potential_damage_per_target / target.max_health)

	if enemies_hit == 0: return 0.0 # No value if only hitting allies

	score += total_enemy_damage_score * AIScoringWeights.WEIGHT_AOE_TARGET_ENEMY
	score += total_ally_damage_penalty


	return max(0.0, score)

func generate_targets(from: CombatCharacter, map: CombatMap) -> Array[TargetInfo]:
	# Self-centered AoE, affects all characters except caster
	var caster_pos = map.get_cell_coords(from.global_position)
	var characters_hit = []

	for cell in HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex): return true):
		var character = map.get_character(cell)
		if is_valid_target_type(from, character):
			characters_hit.append(character)


	if not characters_hit.is_empty():
		return [TargetInfo.new(
			TargetInfo.TargetType.SELF_AOE_ACTIVATION,
			from,
			caster_pos,
			characters_hit # All non-caster characters hit
		)]
	else:
		return []

func _on_reached_target():
	if is_instance_valid(curr_effect):
		curr_effect.queue_free()

	for target in targets:
		if is_instance_valid(target):
			caster.deal_damage(target, damage_mult)

	skill_finished.emit()

func get_skill_name() -> String:
	return "Soul Harvest"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to all characters in a " + str(get_skill_range()) + "-cell radius.\n" + \
		"Cooldown: " + str(max_cooldown) + " turns.\n" + \
		"Range: " + str(get_skill_range()) + " cells.\n"

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/soul_harvest.png")

func get_skill_range() -> int:
	return 2

func target_allies() -> bool:
	return true

func target_enemies() -> bool:
	return true # Implicitly via area

func target_self() -> bool:
	return false

func is_melee() -> bool:
	# Consistent with Lightning Storm / Whirlwind
	return true

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
	var caster_pos = map.get_cell_coords(from.global_position)
	curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex: Vector2i): return true).filter(func (cell): return map.can_walk((cell)))

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)
		var character = map.get_character(cell)
		if character:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)
		if cell == caster_pos:
			map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 0)

	return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
	var highlight_color = 3
	if mouse_pos in curr_highlighted_cells:
		highlight_color = 4

	for cell in curr_highlighted_cells:
		map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), highlight_color)
		var character = map.get_character(cell)
		var caster_pos = map.get_cell_coords(from.global_position)

		if character:
			var char_highlight = 4; var char_hover_highlight = 5
			if cell == caster_pos:
				char_highlight = 0; char_hover_highlight = 0

			if mouse_pos in curr_highlighted_cells:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), char_hover_highlight)
			else:
				map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), char_highlight)

	return curr_highlighted_cells
