extends TileMap
class_name CombatMap

@export var debug_mode: bool = false

var astar: AStar2D = AStar2D.new()
var cell_ids: Dictionary = {}

var characters: Array[CombatCharacter]
var turn = -1
var player_count = 0
var enemy_count = 0

signal combat_ended(victory: bool)

func _ready():
	if debug_mode : 
		enter_combat([PartyMember.new_rand()], [Character.new("Dark Cultist", 1, 2, 2)])


func enter_combat(party: Array[PartyMember], enemies: Array[Character]) : 

	for character in characters : 
		character.queue_free()
	characters.clear()

	player_count = party.size()
	enemy_count = enemies.size()

	var player_characters = []
	for i in range(0, max(party.size(), enemies.size())) : 
		if i < party.size() : 
			var player: CombatCharacter = PlayerCombatCharacter.new_character(party[i])
			get_node("characters/player_characters").add_child(player)
			player.position = map_to_local(Vector2i(i + 1, 6))
			player_characters.append(player)

			characters.append(player)
			player.target_reached.connect(_on_target_reached)
			player.character_died.connect(_on_character_died)

		if i < enemies.size() : 
			var enemy: CombatCharacter = AICombatCharacter.new_character(enemies[i])
			get_node("characters/enemies").add_child(enemy)
			enemy.position = map_to_local(Vector2i(9 - i, 1))

			characters.append(enemy)
			enemy.changed_cell.connect(_on_enemy_cell_changed)
			enemy.target_reached.connect(_on_target_reached)
			enemy.character_died.connect(_on_character_died)	
			enemy.set_player_units(player_characters)

	_setup_astar()

	next_turn()

var oddr_direction_differences = [
	[[+1,  0], [ 0, -1], [-1, -1], 
	 [-1,  0], [-1, +1], [ 0, +1]],
	
	[[+1,  0], [+1, -1], [ 0, -1], 
	 [-1,  0], [ 0, +1], [+1, +1]],
]
	
func is_neighbour(hex, pos) : 
	var parity = hex.y & 1
	for i in range(0, 6) :
		var diff = oddr_direction_differences[parity][i]
		if Vector2i(hex.x + diff[0], hex.y + diff[1]) == pos : 
			return true
	return false

func cell_occupied(hex) : 
	for character in characters : 
		if get_cell_coords(character.global_position) == hex : 
			return true
	return false

func enemy_in_cell(hex) -> CombatCharacter: 
	for character in characters : 
		if character is AICombatCharacter && get_cell_coords(character.global_position) == hex : 
			return character
	return null
	
func can_walk(hex) : 
	return get_cell_source_id(0, hex) == 22 && get_cell_atlas_coords(0, hex).x in characters[turn].walkable_cells


func reset_neighbours(hex) : 
	for i in range(0, 6) :
		var neighbour = _oddr_offset_neighbor(hex, i)
		set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 0)

func highlight_neighbours(hex) : 
	for i in range(0, 6) :
		var neighbour = _oddr_offset_neighbor(hex, i)
		if can_walk(neighbour) && !cell_occupied(neighbour): 
			set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 1)
		if enemy_in_cell(neighbour) : 
			set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 3)

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

func get_character(hex) -> CombatCharacter : 
	for character in characters : 
		if get_cell_coords(character.global_position) == hex : 
			return character
	return null

func get_cell_coords(pos) : 
	return local_to_map(to_local(pos))

func get_cell_astar_id(cell_pos) : 
	return cell_ids[get_cell_coords(cell_pos)]

func next_turn() : 
	print("turn : ", turn, "new turn : ", (turn + 1) % characters.size())
	turn = (turn + 1) % characters.size()
	characters[turn].take_turn()	


func _on_target_reached() :
	next_turn()

func _on_character_died(character) : 
	var char_index = characters.find(character)
	characters.erase(character)

	if character is PlayerCombatCharacter : 
		player_count -= 1
	else : 
		enemy_count -= 1

	print("turn : ", turn, " new turn : ", turn - 1)
	if turn > char_index :
		turn -= 1
	
	if player_count == 0 :
		print("You lost")
		for enemy in characters : 
			character.queue_free()
		emit_signal("combat_ended", false)

	elif enemy_count == 0 : 
		print("You won")
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

	print(astar.get_point_path(10, 12))

func _on_enemy_cell_changed(from: Vector2i, to: Vector2i) : 
	astar.set_point_disabled(cell_ids[from], false)
	astar.set_point_disabled(cell_ids[to], true)
