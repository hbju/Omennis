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
	new_char.character = _char
	return new_char


func _ready():
	super()
	walkable_cells = [0, 2, 6, 7, 8, 9, 10, 11, 14, 15, 16]


##
## Take a turn for the AI character, moving and attacking the closest player if possible
## If no player is in range, the AI will move to a random walkable cell
##
func take_turn():
	if char_statuses["stunned"] > 0 :
		char_statuses["stunned"] -= 1
		if char_statuses["stunned"] == 0:
			curr_stun_animation.queue_free()
			curr_stun_animation = null
		turn_finished.emit()
		return


	var party = map.get_alive_party_members()
	map.enable_disable_cells(true, false, true)
	var closest_player_and_path = get_closest_player_path(party)
	var closest_player = closest_player_and_path[0]
	var path = closest_player_and_path[1]
	if closest_player and path.size() > 0:
		if path.size() > 2:
			move_to(map.map_to_local(path[1]))

		if path.size() == 2:
			attack(map.to_local(closest_player.global_position))
			deal_damage(closest_player, 1)	

	else : 
		var random_neighbor = map.get_random_walkable_neighbor(map.get_cell_coords(global_position), walkable_cells)
		if random_neighbor != Vector2i(-INF, -INF):
			move_to(map.map_to_local(random_neighbor))
		else :
			turn_finished.emit()

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

	

