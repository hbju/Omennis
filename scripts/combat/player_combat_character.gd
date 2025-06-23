extends CombatCharacter
class_name PlayerCombatCharacter

const player_character = preload("res://scenes/player_combat_character.tscn")

var is_turn = false
var action_in_progress = false

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
	_char.base_skill.skill_finished.connect(new_char.finish_turn)
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
	if character.base_skill:
		character.base_skill.decrease_cooldown()

	if (char_statuses["stunned"] > 0) :
		finish_turn()
		return

	_get_move_cells()

	is_turn = true
	action_in_progress = false

func finish_turn() : 
	map.reset_neighbours(action_cells)
	action_cells = []
	current_skill = null
	is_turn = false
	action_in_progress = false
	super()


##
## Highlight the cells that can be targeted by a skill [br]
## [code] skill [/code]: Skill to highlight the possible targets for [br]
## [code] return [/code]: void
##
func highlight_skill(skill: Skill) : 
	map.reset_map()

	if current_skill == skill : 
		_get_move_cells()
		return

	current_skill = skill
	action_cells = skill.highlight_targets(self, map)

##
## Process the input of the player, moving the character or attacking an enemy [br]
## [code] event [/code]: Input event to process [br]
## [code] return [/code]: void
##
func _input(event):
	if not is_turn or action_in_progress: 
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
					action_in_progress = true
					map.reset_neighbours(action_cells)

				var enemy = map.enemy_in_cell(click_pos)
				if click_pos in action_cells && enemy : 
					deal_damage(enemy, 1)
					attack(map.to_local(enemy.global_position))
					action_in_progress = true
					map.reset_neighbours(action_cells)

			else : 
				if click_pos in action_cells :
					if (current_skill.use_skill(self, click_pos, map)) :
						action_in_progress = true

	if event.is_action_pressed("combat_cancel_action") :
		map.reset_map()
		_get_move_cells()

func _get_move_cells() -> void :
	if char_statuses["rooted"] > 0 :
		action_cells = map.highlight_neighbours(map.get_cell_coords(global_position), 1, 0, 4).filter(func(cell): return map.cell_occupied(cell) and not map.get_cell_coords(global_position) == cell)
		current_skill = null
		return
	action_cells = map.highlight_neighbours(map.get_cell_coords(global_position), 1, 1, 4)
	action_cells.erase(map.get_cell_coords(global_position))
	current_skill = null
