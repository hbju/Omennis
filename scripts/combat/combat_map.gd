extends TileMap
class_name CombatMap

@onready var skill_bar_ui: SkillBarUI = $UI/skill_ui

@export var debug_mode: bool = false

var astar: AStar2D = AStar2D.new()
var cell_ids: Dictionary = {}

var characters: Array[CombatCharacter]
var turn = -1
var player_count = 0
var enemy_count = 0

signal combat_ended(victory: bool)

func _ready():
	skill_bar_ui.choose_target.connect(_on_skill_selected)
	if debug_mode : 
		enter_combat([PartyMember.new_rand()], [Character.new("Dark Cultist", 1, 2, 2)])


##
## Enters the combat mode with the specified party members and enemies. [br]
##
## [code]party [/code]: An array of PartyMember objects representing the player's party members.[br]
## [code]enemies [/code]: An array of Character objects representing the enemies in the combat.
##
func enter_combat(party: Array[PartyMember], enemies: Array[Character]) :

	for character in characters : 
		character.queue_free()
	characters.clear()

	player_count = party.size()
	enemy_count = enemies.size()

	for i in range(0, max(party.size(), enemies.size())) : 
		if i < party.size() : 
			var player: CombatCharacter = PlayerCombatCharacter.new_character(party[i])
			get_node("characters/player_characters").add_child(player)
			player.position = map_to_local(Vector2i(i + 3, 2))

			characters.append(player)
			player.turn_finished.connect(_on_target_reached)
			player.character_died.connect(_on_character_died)

		if i < enemies.size() : 
			var enemy: CombatCharacter = AICombatCharacter.new_character(enemies[i])
			get_node("characters/enemies").add_child(enemy)
			enemy.position = map_to_local(Vector2i(8 - i, 2))

			characters.append(enemy)
			enemy.turn_finished.connect(_on_target_reached)
			enemy.character_died.connect(_on_character_died)	

	_setup_astar()

	next_turn()



##
##  Advances the turn to the next character.
##  
func next_turn() :
	turn = (turn + 1) % characters.size()
	print(characters[turn].character.skill_list)
	characters[turn].take_turn()	
	skill_bar_ui.update_ui(characters[turn].character)

var oddr_direction_differences = [
	[[+1,  0], [ 0, -1], [-1, -1], 
	 [-1,  0], [-1, +1], [ 0, +1]],
	
	[[+1,  0], [+1, -1], [ 0, -1], 
	 [-1,  0], [ 0, +1], [+1, +1]],
]

##
## Checks if a given hexagon is a neighbor of another hexagon. [br]
##
## [code]hex [/code]: The hexagon to check if it is a neighbor. [br]
## [code]pos [/code]: The hexagon to check if it is a neighbor of the first hexagon. [br]
## [code]return [/code]: True if the second hexagon is a neighbor of the first hexagon, false otherwise.
##
func is_neighbour(hex, pos) : 
	var parity = hex.y & 1
	for i in range(0, 6) :
		var diff = oddr_direction_differences[parity][i]
		if Vector2i(hex.x + diff[0], hex.y + diff[1]) == pos : 
			return true
	return false

##
## Checks if a given hexagon is occupied by a character.
##
## [code]hex [/code]: The hexagon to check if it is occupied.
## [code]return [/code]: True if the hexagon is occupied, false otherwise.
##
func cell_occupied(hex) : 
	for character in characters : 
		if get_cell_coords(character.global_position) == hex : 
			return true
	return false

##
## Returns the enemy character in a given hexagon. [br]
##
## [code]hex [/code]: The hexagon to check for an enemy character. [br]
## [code]return [/code]: The enemy character in the hexagon, or null if there is none. [br]
##
func enemy_in_cell(hex) -> CombatCharacter: 
	for character in characters : 
		if character is AICombatCharacter && get_cell_coords(character.global_position) == hex : 
			return character
	return null

##
## Returns the character in a given hexagon on the combat map.
##
## [code]hex [/code]: The hexagon to check for a character.[br]
## [code]return [/code]: The character in the hexagon, or null if there is none.
##
func get_character(hex) -> CombatCharacter : 
	for character in characters : 
		if get_cell_coords(character.global_position) == hex : 
			return character
	return null
	
##
## Checks if a given hexagon is walkable. [br]
##
## [code]hex [/code]: The hexagon to check if it is walkable. [br]
## [code]return [/code]: True if the hexagon is walkable, false otherwise. [br]
##
func can_walk(hex) : 
	return get_cell_source_id(0, hex) == 22 && get_cell_atlas_coords(0, hex).x in characters[turn].walkable_cells

##
## Resets the highlighted neighboring cells of a given hexagon on the combat map. [br]
##
## [code]highlighted_cells [/code]: An array of previously highlighted cells. [br]
##
func reset_neighbours(highlighted_cells: Array[Vector2i]) : 
	for neighbour in highlighted_cells :
		set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 0)



## 
## Highlights the neighboring cells of a given hexagon on the combat map.[br]
##
## [code]hex [/code]: The hexagon to highlight its neighbors.[br]
## [code]highlight_range [/code]: The range of neighbors to highlight (default: 0).[br]
## [code]empty_cell_alt [/code]: The alternative tile to use for empty cells (default: 1).[br]
## [code]highlighted_cells [/code]: An array of previously highlighted cells (default: []).[br]
## [code]return [/code]: An array of Vector2i representing the coordinates of the highlighted neighboring cells.
##
func highlight_neighbours(hex, highlight_range = 1, empty_cell_alt: int = 1, highlighted_cells: Array[Vector2i] = []) -> Array[Vector2i]:
	# Function implementation goes here
	highlighted_cells.append(hex) 
	for i in range(0, 6) :
		var neighbour = _oddr_offset_neighbor(hex, i)
		if neighbour in highlighted_cells : 
			continue

		if can_walk(neighbour) && !cell_occupied(neighbour): 
			set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), empty_cell_alt)
			if highlight_range > 1 : 
				highlight_neighbours(neighbour, highlight_range - 1, empty_cell_alt, highlighted_cells)
			else : 
				highlighted_cells.append(neighbour)
		if enemy_in_cell(neighbour) : 
			set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 3)
			highlighted_cells.append(neighbour)
	return highlighted_cells


##
## Highlights the columns of a given hexagon on the combat map.[br]
##
## [code]hex [/code]: The hexagon to highlight its columns.[br]
## [code]highlight_range [/code]: The range of columns to highlight (default: 1).[br]
## [code]return [/code]: An array of Vector2i representing the coordinates of the highlighted columns.
##
func highlight_columns(hex, highlight_range) -> Array[Vector2i] : 
	var highlighted_cells: Array[Vector2i] = []
	for i in range(0, 6) : 
		var neighbour = _oddr_offset_neighbor(hex, i)
		for j in range(0, highlight_range - 1) : 
			neighbour = _oddr_offset_neighbor(neighbour, i)
			if not can_walk(neighbour) :
				break
			if cell_occupied(neighbour) :
				set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 3)
			else : 
				set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 4)
			highlighted_cells.append(neighbour)
	return highlighted_cells


##
## Returns the list of party members still alive in the combat.
##
## [code]return [/code]: An array of PlayerCombatCharacter objects representing the alive party members.
##
func get_alive_party_members() -> Array[PlayerCombatCharacter] : 
	var alive_party_members: Array[PlayerCombatCharacter] = []
	for character in characters : 
		if character is PlayerCombatCharacter : 
			alive_party_members.append(character)
	return alive_party_members

##
## Finds a random cell in the vicinity of the cell [code] hex [/code] on the combat map.[br]
##
## [code]hex [/code]: The hexagon to find a random cell in its vicinity.[br]
## [code]walkable_cells [/code]: An array of walkable cells on the combat map.[br]
## [code]return [/code]: A Vector2i representing the coordinates of the random cell.
##
func get_random_walkable_neighbor(hex: Vector2i, walkable_cells: Array[int]) -> Vector2i : 
	var parity = hex.y & 1
	var possible_neighbours = []
	for i in range(0, 6) :
		var diff = oddr_direction_differences[parity][i]
		var neighbour = Vector2i(hex.x + diff[0], hex.y + diff[1])
		if walkable_cells.has(get_cell_atlas_coords(0, neighbour).x) && !cell_occupied(neighbour) : 
			possible_neighbours.append(neighbour)
	if possible_neighbours.size() == 0 : 
		return Vector2i(-INF, -INF)
	return possible_neighbours[randi() % possible_neighbours.size()]

##
## Returns the hex-grid coordinates of a given position on the combat map.
##
## [code]pos [/code]: The position to get its cell coordinates.[br]
## [code]return [/code]: A Vector2i representing the coordinates of the position in the hex grid.
##
func get_cell_coords(pos) : 
	return local_to_map(to_local(pos))

##
## Returns the A* ID of a given position on the combat map.
##
## [code]cell_pos [/code]: The position to get its A* ID.[br]
## [code]return [/code]: The A* ID of the position.
##
func get_cell_astar_id(cell_pos) : 
	return cell_ids[get_cell_coords(cell_pos)]


##
## Disables or enables the cells occupied by the enemies or party members. [br]
##
## [code]enemies [/code]: A boolean indicating whether to disable or enable the cells occupied by the enemies.[br]
## [code]party [/code]: A boolean indicating whether to disable or enable the cells occupied by the party members.[br]
## [code]disable [/code]: A boolean indicating whether to disable or enable the cells.
##
func enable_disable_cells(enemies: bool, party: bool, disable: bool) : 
	for character in characters : 
			if enemies and character is AICombatCharacter : 
				astar.set_point_disabled(cell_ids[get_cell_coords(character.global_position)], disable)
			if party and character is PlayerCombatCharacter :
				astar.set_point_disabled(cell_ids[get_cell_coords(character.global_position)], disable)

##
## Turn the combat UI on or off.
##
func toggle_ui() : 
	$UI.visible = !$UI.visible


func _on_target_reached() :
	next_turn()

func _on_character_died(character) : 
	var char_index = characters.find(character)
	characters.erase(character)

	if character is PlayerCombatCharacter : 
		player_count -= 1
	else : 
		enemy_count -= 1

	if turn > char_index :
		turn -= 1
	
	if player_count == 0 :
		for enemy in characters : 
			character.queue_free()
		emit_signal("combat_ended", false)

	elif enemy_count == 0 : 
		emit_signal("combat_ended", true)

func _oddr_offset_neighbor(hex, direction):
	var parity = hex.y & 1
	var diff = oddr_direction_differences[parity][direction]
	return Vector2i(hex.x + diff[0], hex.y + diff[1])

func _setup_astar():
	var enemy_walkable_cells = [0, 2, 6, 7, 8, 9, 10, 11, 14, 15, 16]
	var id = 0

	for hex in get_used_cells(0):
		if get_cell_atlas_coords(0, hex).x in enemy_walkable_cells: # Assuming -1 is an invalid tile
			astar.add_point(id, hex)
			cell_ids[hex] = id
			id += 1

	for hex in cell_ids.keys():
		for i in range(0, 6):
			var neighbour = _oddr_offset_neighbor(hex, i)
			if cell_ids.has(neighbour):
				astar.connect_points(cell_ids[hex], cell_ids[neighbour], false)


func _on_skill_selected(skill) : 
	if characters[turn] is PlayerCombatCharacter : 
		(characters[turn] as PlayerCombatCharacter).highlight_skill(skill)
