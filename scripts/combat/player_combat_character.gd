extends CombatCharacter
class_name PlayerCombatCharacter

const player_character = preload("res://scenes/player_combat_character.tscn")

var is_turn = false

var action_cells: Array[Vector2i] = []

var current_skill: Skill = null
signal use_skill(skill: Skill)

##
## Create a new player character [br]
## [code] _char [/code]: Character to create the player character from  [br]
## [code] return [/code]: the new player character
##
static func new_character(_char: Character) -> PlayerCombatCharacter:
	var new_char: PlayerCombatCharacter = player_character.instantiate()
	new_char.character = _char
	for skill in _char.skill_list : 
		skill.skill_finished.connect(new_char.finish_turn)
	return new_char



func _ready():
	super()
	walkable_cells = [0, 2, 6, 7, 8, 9, 10, 11, 14, 15, 16]

##
## Make the player character take a turn, decreasing the cooldown of all skills, highlighting the possible actions and waiting for the player to make a move [br]
## [code] return [/code]: void
##
func take_turn() : 
	for skill in character.skill_list : 
		skill.decrease_cooldown()

	action_cells = map.highlight_neighbours(map.get_cell_coords(global_position), 1, 1, 3)
	action_cells.erase(map.get_cell_coords(global_position))
	current_skill = null
	is_turn = true

func finish_turn() : 
	map.reset_neighbours(action_cells)
	super()


##
## Highlight the cells that can be targeted by a skill [br]
## [code] skill [/code]: Skill to highlight the possible targets for [br]
## [code] return [/code]: void
##
func highlight_skill(skill: Skill) : 
	map.reset_neighbours(action_cells)

	if current_skill == skill : 
		action_cells = map.highlight_neighbours(map.get_cell_coords(global_position), 1, 1, 3)
		action_cells.erase(map.get_cell_coords(global_position))
		current_skill = null
		return

	current_skill = skill
	action_cells = skill.highlight_targets(self, map)

##
## Process the input of the player, moving the character or attacking an enemy [br]
## [code] event [/code]: Input event to process [br]
## [code] return [/code]: void
##
func _input(event):
	if not is_turn: 
		return
	
	if event is InputEventMouseMotion :
		if current_skill : 
			var mouse_cell = map.get_cell_coords(get_global_mouse_position())
			map.reset_neighbours(action_cells)
			action_cells = current_skill.highlight_mouse_pos(self, mouse_cell, map)
		


	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var click_pos = map.get_cell_coords(get_global_mouse_position())
			if not current_skill :
				if click_pos in action_cells && map.can_walk(click_pos) && !map.cell_occupied(click_pos): 
					move_to(map.map_to_local(click_pos))
					is_turn = false
					map.reset_neighbours(action_cells)

				var enemy = map.enemy_in_cell(click_pos)
				if click_pos in action_cells && enemy : 
					enemy.take_damage(damage)
					attack(map.to_local(enemy.global_position))
					is_turn = false
					map.reset_neighbours(action_cells)

			else : 
				if click_pos in action_cells :
					var skill_used = current_skill.use_skill(self, click_pos, map)
					map.reset_neighbours(action_cells)
					if skill_used : 
						current_skill = null