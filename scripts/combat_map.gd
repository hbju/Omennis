extends TileMap

@onready var characters: Array = get_node("characters").get_children()
var turn = 0
var turn_finished = true
var old_pos = null

func _ready():
	var player = characters[turn]
	var player_pos = local_to_map(to_local(player.global_position))
	highlight_neighbours(player_pos)

	for character in characters : 
		character.target_reached.connect(_on_target_reached)
		character.character_died.connect(_on_character_died)

var oddr_direction_differences = [
	[[+1,  0], [ 0, -1], [-1, -1], 
	 [-1,  0], [-1, +1], [ 0, +1]],
	
	[[+1,  0], [+1, -1], [ 0, -1], 
	 [-1,  0], [ 0, +1], [+1, +1]],
]

var nature_walkable_cells = [0, 2, 6, 7, 8, 9, 10, 11, 14, 15, 16]

func oddr_offset_neighbor(hex, direction):
	var parity = hex.y & 1
	var diff = oddr_direction_differences[parity][direction]
	return Vector2i(hex.x + diff[0], hex.y + diff[1])
	
func is_neighbour(hex, pos) : 
	var parity = hex.y & 1
	for i in range(0, 6) :
		var diff = oddr_direction_differences[parity][i]
		if Vector2i(hex.x + diff[0], hex.y + diff[1]) == pos : 
			return true
	return false

func cell_occupied(hex) : 
	for character in characters : 
		if local_to_map(to_local(character.global_position)) == hex : 
			return true
	return false
	
func can_walk(hex) : 
	return get_cell_source_id(0, hex) == 22 && get_cell_atlas_coords(0, hex).x in nature_walkable_cells


func reset_neighbours(hex) : 
	for i in range(0, 6) :
		var neighbour = oddr_offset_neighbor(hex, i)
		set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 0)

func highlight_neighbours(hex) : 
	for i in range(0, 6) :
		var neighbour = oddr_offset_neighbor(hex, i)
		if can_walk(neighbour) : 
			set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 1)
		if cell_occupied(neighbour) : 
			set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 3)

func next_turn() : 
	reset_neighbours(old_pos)

	turn = (turn + 1) % characters.size()

	var player = characters[turn]
	var player_pos = local_to_map(to_local(player.global_position))
	highlight_neighbours(player_pos)
	old_pos = player_pos
			
	
func _input(event):
	if not turn_finished : 
		return

	var player = characters[turn]
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var click_pos = local_to_map(to_local(get_global_mouse_position()))
			var player_pos = local_to_map(to_local(player.global_position))
			if is_neighbour(player_pos, click_pos) && can_walk(click_pos) && !cell_occupied(click_pos): 
				player.move_to(map_to_local(click_pos))
				turn_finished = false
				old_pos = player_pos
			if is_neighbour(player_pos, click_pos) && cell_occupied(click_pos) : 
				for character in characters : 
					if local_to_map(to_local(character.global_position)) == click_pos : 
						if character != player : 
							character.take_damage(player.damage)

func _on_target_reached() :
	turn_finished = true
	next_turn()

func _on_character_died(character) : 
	characters.erase(character)
	if turn >= characters.size() : 
		turn -= 1
	if characters.size() == 1 : 
		print("Game Over")
		get_tree().quit()
				
