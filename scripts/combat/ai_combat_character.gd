extends CombatCharacter
class_name AICombatCharacter

const enemy_character = preload("res://scenes/ai_combat_character.tscn")

var attack_range: int = 1
var move_range: int = 1 # Number of tiles the enemy can move per turn


##
## Create a new AI enemy character [br]
## [code] _char [/code]: Character to create the AI character from  [br]
## [code] return [/code]: the new AI character
##
static func new_character(_char: Character) -> AICombatCharacter:
	var new_char = enemy_character.instantiate()
	new_char.health = 10
	new_char.character = _char
	for skill in _char.skill_list : 
		skill.skill_finished.connect(new_char.finish_turn)
	return new_char


func _ready():
	super()
	walkable_cells = [0, 2, 6, 7, 8, 9, 10, 11, 14, 15, 16]


##
## Take a turn for the AI character, moving and attacking the closest player if possible
## If no player is in range, the AI will move to a random walkable cell
##
func take_turn():
	for skill in character.skill_list : 
		skill.decrease_cooldown()

	if char_statuses["stunned"] > 0 :
		char_statuses["stunned"] -= 1
		if char_statuses["stunned"] == 0:
			curr_stun_animation.queue_free()
			curr_stun_animation = null
		turn_finished.emit()
		return


	var party = map.get_alive_party_members()
	var current_pos = map.get_cell_coords(global_position)
	var usable_skills = get_usable_skills()

	map.enable_disable_cells(true, false, true)

	var possible_actions = evaluate_potential_actions(current_pos, party, usable_skills)

	if possible_actions.size() > 0:
		var selected_action = score_and_select_action(possible_actions)
		print("Selected Action: ", selected_action.type, " | Skill: ", selected_action.skill.get_skill_name() if selected_action.skill else "N/A", " | Target: ", selected_action.target_character.character.character_name if selected_action.target_character else str(selected_action.target_cell), " | Score: ", selected_action.score)

		match selected_action.type:
			"attack":
				attack(map.to_local(selected_action.target_character.global_position))
				deal_damage(selected_action.target_character, 1)
			"skill":
				selected_action.skill.use_skill(self, selected_action.target_cell, map)
			"move":
				move_to(map.map_to_local(selected_action.target_cell))
			"wait" :
				finish_turn()

	map.enable_disable_cells(true, false, false)


##
## Get the closest player and the path to reach him
## [code] party [/code]: Array of players to check for the closest one
## [code] return [/code]: Array containing the closest player and the path to reach him
##
func get_closest_player_path(party: Array[PlayerCombatCharacter]) -> Array:
	var closest_player = null
	var closest_path = null
	for player in party:
		var path = _calculate_path_to_character(map.get_cell_coords(player.global_position))
		var distance = path.size()
		if  closest_path == null or distance < closest_path.size():
			closest_path = path
			closest_player = player
	return [closest_player, closest_path]

func get_lowest_health_player_path(party: Array[PlayerCombatCharacter]) -> Array:
	party = party.duplicate()
	party.sort_custom(func (a, b): return a.health < b.health)
	for player in party:
		var path = _calculate_path_to_character(map.get_cell_coords(player.global_position))
		var distance = path.size()
		if distance > 0:
			return [player, path] 
	return [null, null]

	

func get_usable_skills() -> Array[Skill]:
	var usable_skills: Array[Skill] = []
	for skill in character.skill_list:
		if skill.cooldown == 0:
			usable_skills.append(skill)
	return usable_skills

func evaluate_potential_actions(current_pos: Vector2i, alive_players: Array[PlayerCombatCharacter], usable_skills: Array[Skill]) -> Array[Dictionary] :
	var possible_actions: Array[Dictionary] = []
	
	var attackable_cells = HexHelper.hex_reachable(current_pos, attack_range, map.can_walk)

	for cell in attackable_cells:
		if HexHelper.distance(current_pos, cell) > 0: # Don't attack self cell
			var target_char = map.get_character(cell)
			if target_char and target_char is PlayerCombatCharacter: # TODO have to check if the target is an enemy
				var action = {
					"type": "attack",
					"target_character": target_char,
					"target_cell": cell,
					"skill": null, # No specific skill object for basic attack
					"targets_hit": [target_char], # List of characters affected
					"score": 0.0 # Score will be calculated later
				}
				possible_actions.append(action)
				# print("Added Basic Attack action vs ", target_char.character.character_name)
			
	for skill in usable_skills:
		var potential_initiations: Array[TargetInfo] = skill.generate_targets(self, map)

		for initiation_info in potential_initiations:
			possible_actions.append({
				"type": "skill",
				"target_character": initiation_info.primary_target, # The primary target/caster or null
				"target_cell": initiation_info.target_cell,     # The cell targeted or AoE center
				"skill": skill,                                 # The skill being used
				"targets_hit": initiation_info.affected_targets,# The characters affected
				"score": 0.0                                    # Score calculated later
			})
			# print("Added Skill Action: ", skill.get_skill_name(), " based on ", initiation_info._to_string())


	var can_act_now = false
	for action in possible_actions:
		if action.type == "attack" or action.type == "skill":
			can_act_now = true
			break

	if not can_act_now and not alive_players.is_empty() and not char_statuses["rooted"] > 0:
		for player in alive_players:
			var path = _calculate_path_to_character(map.get_cell_coords(player.global_position))
			if path.size() > 1: 
				var primary_target = player
				possible_actions.append({
					"type": "move",
					"target_character": primary_target,
					"target_cell": path[1],
					"skill": null,
					"targets_hit": [],
					"score": 0.0 # Score calculated later
				}) 
				# print("Added Move Action towards ", primary_target.character.character_name, " to cell ", path[1])
		

	possible_actions.append({
		"type": "wait",
		"target_character": null,
		"target_cell": current_pos, # Wait at current location
		"skill": null,
		"targets_hit": [],
		"score": 1.0 # Minimal base score for waiting
	})

	# print("Generated ", possible_actions.size(), " possible actions.")
	return possible_actions

func score_and_select_action(possible_actions: Array[Dictionary]) -> Dictionary:
	if possible_actions.is_empty(): return {} # Should not happen due to Wait action

	var scored_actions: Array[Dictionary] = []
	for action in possible_actions:
		var current_score = 0.0
		match action.type:
			"attack":
				current_score = score_basic_attack(self, action.targets_hit[0]) # Pass the single target
			"skill":
				current_score = action.skill.score_action(self, action.targets_hit, action.target_cell, map)
			"move":
				current_score = score_move_action(self, action.target_character, action.target_cell)
			"wait":
				current_score = action.score # Use default wait score

		action.score = current_score
		scored_actions.append(action)
		# print("Scored ", action.type, " | Skill: ", action.skill.get_skill_name() if action.skill else "N/A", " | Target: ", action.target_character.character.character_name if action.target_character else str(action.target_cell), " | Score: ", current_score)

	# Sort by score descending
	scored_actions.sort_custom(func(a, b): return a.score > b.score)

	# TODO: Add weighted random selection here instead of just taking the best?
	if not scored_actions.is_empty():
		# print("Selected Action: ", scored_actions[0].type, " with score ", scored_actions[0].score)
		return scored_actions[0]
	else:
		return {} # Fallback

func score_basic_attack(caster: AICombatCharacter, target: CombatCharacter) -> float:
	var score = 10.0 # Placeholder
	var potential_damage = caster.get_damage() * 1.0 # Basic attack damage mult = 1?
	score += potential_damage * AIScoringWeights.WEIGHT_DAMAGE
	if target.health <= potential_damage: score += AIScoringWeights.WEIGHT_KILL_BONUS
	return score

func score_move_action(caster: AICombatCharacter, primary_target: CombatCharacter, destination_cell: Vector2i) -> float:
	var score = 5.0 # Placeholder
	var current_pos = map.get_cell_coords(caster.global_position)
	if primary_target:
		var target_pos = map.get_cell_coords(primary_target.global_position)
		var current_dist = HexHelper.distance(current_pos, target_pos)
		var new_dist = HexHelper.distance(destination_cell, target_pos)
		score += (current_dist - new_dist) * AIScoringWeights.WEIGHT_POSITIONING_CLOSER
	return score