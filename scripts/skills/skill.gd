class_name Skill

var cooldown: int
signal skill_finished()

## Skill functions

##
## Decrease the cooldown of the skill by 1
##
func decrease_cooldown():
	if cooldown > 0:
		cooldown -= 1

##
## Make _from use the skill on _target. This function should be overriden by the child class
##
## [code] _from [/code]: The CombatCharacter that is using the skill
## [code] _target [/code]: The CombatCharacter that is being targeted by the skill
## [code] return [/code]: Whether the skill was successfully used
##
func use_skill(_from: CombatCharacter, _skill_pos: Vector2i, _map: CombatMap) -> bool :
	assert(false, "function not implemented")
	return false

##
## Get the name of the skill
##
func get_skill_name() -> String:
	assert(false, "function not implemented")
	return ""

##
## Get the description of the skill
##
func get_skill_description() -> String:
	assert(false, "function not implemented")
	return ""

##
## Get the icon of the skill
##
func get_skill_icon() -> Texture:
	assert(false, "function not implemented")
	return null

##
## Get the range of the skill
##
func get_skill_range() -> int:
	assert(false, "function not implemented")
	return -1

##
## Get whether the skill targets allies, enemies, or self
##
func target_allies() -> bool:
	assert(false, "function not implemented")
	return false

func target_enemies() -> bool:
	assert(false, "function not implemented")
	return false

func target_self() -> bool:
	assert(false, "function not implemented")
	return false

##
## Checks if 'target' is a valid type (enemy/ally) for 'skill' cast by 'from'.
## Does NOT check range or if target is null.
##
func is_valid_target_type(from: CombatCharacter, target: CombatCharacter) -> bool:
	if not from or not target: return false 

	if target_enemies():
		if (target.char_statuses.get("stealth", 0) == 0) and ((from is PlayerCombatCharacter and target is AICombatCharacter) or \
		   (from is AICombatCharacter and target is PlayerCombatCharacter)):
			return true

	if target_allies():
		if target != from and ( \
		   (from is PlayerCombatCharacter and target is PlayerCombatCharacter) or \
		   (from is AICombatCharacter and target is AICombatCharacter) ):
			return true

	if target_self():
		if target == from:
			return true
			
	return false

func score_action(_from: CombatCharacter, _potential_targets: Array[CombatCharacter], _target_cell: Vector2i, _map: CombatMap) -> float:
	# Base implementation - should be overridden by subclasses
	# Returns a low score if not overridden, indicating low priority or error
	printerr("score_action not implemented for skill: ", get_skill_name())
	return 0.1

##
## Generates all possible valid initiation targets/locations for this skill
## from the perspective of the 'caster' on the current 'map'.
## Returns an Array of TargetInfo objects.
##
func generate_targets(_caster: CombatCharacter, _map: CombatMap) -> Array[TargetInfo]:
	printerr("generate_targets() not implemented for skill: ", get_skill_name())
	return []

##
## Get the remaining cooldown of the skill
##
func get_cooldown() -> int:
	return cooldown

func highlight_targets(_from: CombatCharacter, _map: CombatMap) -> Array[Vector2i]:
	assert(false, "function not implemented")
	return []

func highlight_mouse_pos(_from: CombatCharacter, _mouse_pos: Vector2i, _map: CombatMap) -> Array[Vector2i]:
	assert(false, "function not implemented")
	return []

##
## Get whether the skill is a melee skill
##
func is_melee() -> bool:
	assert(false, "function not implemented")
	return false

static func _get_characters_in_aoe(center_cell: Vector2i, radius: int, map: CombatMap) -> Array[CombatCharacter]:
	var characters_hit: Array[CombatCharacter] = []
	if radius < 0: return characters_hit # Safety check
	var impact_cells = HexHelper.hex_reachable(center_cell, radius, map.can_walk)
	for cell in impact_cells:
		var char_in_impact = map.get_character(cell)
		if char_in_impact:
			characters_hit.append(char_in_impact)
	return characters_hit
