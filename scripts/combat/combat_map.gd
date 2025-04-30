extends TileMap
class_name CombatMap

@onready var skill_bar_ui: SkillBarUI = $UI/skill_ui
@onready var turn_order_container: HBoxContainer = $UI/turn_order_ui/portraits_container 
const TurnOrderPortraitScene = preload("res://scenes/turn_order_portrait.tscn")



@export var debug_mode: bool = false

const PLAYER_STARTING_POS = [Vector2i(0, 3), Vector2i(1, 3), Vector2i(1, 2), Vector2i(2, 2)]
const ENEMY_STARTING_POS = [Vector2i(6, 1), Vector2i(7, 1), Vector2i(7, 2), Vector2i(6, 2), Vector2i(9, 3), Vector2i(10, 3)]

var astar: AStar2D = AStar2D.new()
var cell_ids: Dictionary = {}

var characters: Array[CombatCharacter]
var turn = -1
var player_count = 0
var enemy_count = 0

const CombatCharacterTooltipScene = preload("res://scenes/character_tooltip.tscn")
var character_tooltip_instance: CombatCharacterTooltipUI

signal combat_ended(victory: bool)

func _ready():
	skill_bar_ui.choose_target.connect(_on_skill_selected)
	if debug_mode : 
		var party: Array[PartyMember] = [PartyMember.new_rand(), PartyMember.new_rand()]
		# party[1].skill_list.append(Charge.new())
		party[1].skill_list.append(DefensiveStance.new())
		# party[0].skill_list.append(MoltenBlade.new())
		# party[0].skill_list.append(FiresparkMage.new())
		party[0].skill_list.append(ArcaneShield.new())
		# party[1].skill_list.append(Decay.new())

		var enemy1 = Character.new("Dark Cultist", 1, 2, 2)
		var enemy2 = Character.new("Dark Cultist", 1, 2, 2)
		var enemies: Array[Character] = [enemy1, enemy2]
		enemy1.skill_list.append(Charge.new())
		enemy1.skill_list.append(DefensiveStance.new())
		enemy2.skill_list.append(FiresparkMage.new())
		enemy2.skill_list.append(ArcaneShield.new())
		
		enter_combat(party, enemies)

	if CombatCharacterTooltipScene :
		character_tooltip_instance = CombatCharacterTooltipScene.instantiate()
		character_tooltip_instance.hide()
		character_tooltip_instance.top_level = true
		$UI.add_child(character_tooltip_instance)
	else :
		printerr("CombatCharacterTooltipScene not found. Tooltip will not be displayed.")


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
			player.position = map_to_local(PLAYER_STARTING_POS[i])

			characters.append(player)
			player.turn_finished.connect(_on_target_reached)
			player.character_died.connect(_on_character_died)

		if i < enemies.size() : 
			var enemy: CombatCharacter = AICombatCharacter.new_character(enemies[i])
			get_node("characters/enemies").add_child(enemy)
			enemy.position = map_to_local(ENEMY_STARTING_POS[i])

			characters.append(enemy)
			enemy.turn_finished.connect(_on_target_reached)
			enemy.character_died.connect(_on_character_died)	

	for character in characters : 
		character.hover_entered.connect(_on_character_hover_entered)
		character.hover_exited.connect(_on_character_hover_exited)

	characters.shuffle()

	_setup_astar()

	next_turn()



##
##  Advances the turn to the next character.
##  
func next_turn() -> void :
	reset_map()
	turn = (turn + 1) % characters.size()
	await get_tree().create_timer(0.5).timeout
	update_turn_order_ui()
	characters[turn].take_turn()	
	skill_bar_ui.update_ui(characters[turn].character)

### --- UI --- ###
func update_turn_order_ui():
	if not turn_order_container or not TurnOrderPortraitScene: return # Safety checks

	# Clear existing portraits
	for child in turn_order_container.get_children():
		child.queue_free()

	# wait for next frame to ensure the UI is ready
	await get_tree().process_frame

	if characters.is_empty(): return # No characters left

	# Display portraits for the next N turns (e.g., 8 or characters.size())
	var num_to_display = min(8, characters.size())
	for i in range(num_to_display):
		var display_char_index = (turn + i) % characters.size()
		var character_to_display = characters[display_char_index]

		var portrait_instance = TurnOrderPortraitScene.instantiate()
		var is_current = (i == 0) # Highlight the first one in the sequence
		portrait_instance.call_deferred("set_character", character_to_display, is_current)
		portrait_instance.mouse_entered.connect(character_to_display.set_highlight.bind(true, Color(0xffffffff)))
		portrait_instance.mouse_exited.connect(character_to_display.set_highlight.bind(false))

		turn_order_container.add_child(portrait_instance)


##
## Checks if a given hexagon is occupied by a character.
##
## [code]hex [/code]: The coords of the hexagon to check if it is occupied.
## [code]return [/code]: True if the hexagon is occupied, false otherwise.
##
func cell_occupied(hex: Vector2i) -> bool : 
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
func enemy_in_cell(hex: Vector2i) -> CombatCharacter: 
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
func get_character(hex: Vector2i) -> CombatCharacter : 
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
func can_walk(hex: Vector2i) -> bool : 
	return get_cell_source_id(0, hex) == 22 && get_cell_atlas_coords(0, hex).x in characters[turn].walkable_cells

##
## Resets the highlighted neighboring cells of a given hexagon on the combat map. [br]
##
## [code]highlighted_cells [/code]: An array of previously highlighted cells. [br]
##
func reset_neighbours(highlighted_cells: Array[Vector2i]) -> void : 
	for neighbour in highlighted_cells :
		set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 0)

func reset_map() -> void : 
	for hex in get_used_cells(0) :
		set_cell(0, hex, 22, get_cell_atlas_coords(0, hex), 0)



## 
## Highlights the neighboring cells of a given hexagon on the combat map.[br]
##
## [code]hex [/code]: The hexagon to highlight its neighbors.[br]
## [code]highlight_range [/code]: The range of neighbors to highlight (default: 0).[br]
## [code]empty_cell_alt [/code]: The alternative tile to use for empty cells (default: 1).[br]
## [code]highlighted_cells [/code]: An array of previously highlighted cells (default: []).[br]
## [code]return [/code]: An array of Vector2i representing the coordinates of the highlighted neighboring cells.
##
func highlight_neighbours(hex: Vector2i, highlight_range = 1, empty_cell_alt: int = 0, enemy_cell_alt: int = 0) -> Array[Vector2i]:
	# Function implementation goes here
	var highlighted_cells = {hex : 0}
	var queue = [hex]

	while queue.size() > 0 :
		var curr_cell = queue.pop_front()
		if highlighted_cells[curr_cell] >= highlight_range : 
			continue
			
		for i in range(0, 6) :
			var neighbour = HexHelper.hex_neighbor(curr_cell, i)
			if not neighbour in highlighted_cells : 
				var curr_range = highlighted_cells[curr_cell]
				if can_walk(neighbour) && !cell_occupied(neighbour): 
					set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), empty_cell_alt)
					highlighted_cells[neighbour] = curr_range + 1
					queue.append(neighbour)

				if enemy_in_cell(neighbour) : 
					set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), enemy_cell_alt)
					highlighted_cells[neighbour] = curr_range + 1

	var cells: Array[Vector2i] = []
	for cell in highlighted_cells.keys() : 
		cells.append(cell)
	return cells


##
## Highlights the columns of a given hexagon on the combat map.[br]
##
## [code]hex [/code]: The hexagon to highlight its columns.[br]
## [code]highlight_range [/code]: The range of columns to highlight (default: 1).[br]
## [code]return [/code]: An array of Vector2i representing the coordinates of the highlighted columns.
##
func highlight_columns(hex: Vector2i, highlight_range: int) -> Array[Vector2i] : 
	var highlighted_cells: Array[Vector2i] = []
	
	for i in range(0, 6) : 
		var neighbour = HexHelper.hex_neighbor(hex, i)
		if not can_walk(neighbour) or cell_occupied(neighbour) : 
			continue
		for j in range(highlight_range - 1) : 
			neighbour = HexHelper.hex_neighbor(neighbour, i)
			if not can_walk(neighbour) :
				break
			if cell_occupied(neighbour) :
				if get_character(neighbour) is AICombatCharacter:
					set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 4)
					highlighted_cells.append(neighbour)
				break
			 
			set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), 3)
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
		var diff = HexHelper.oddr_direction_differences[parity][i]
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
func get_cell_coords(pos: Vector2) -> Vector2i: 
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
func toggle_ui(show_ui: bool) : 
	$UI.visible = show_ui

func _on_character_hover_entered(character: CombatCharacter):
	if character_tooltip_instance and is_instance_valid(character):
		character_tooltip_instance.update_content(character)

		# Position the tooltip (similar logic to skill tree tooltip)
		var mouse_pos = get_global_mouse_position()
		var viewport_rect = get_viewport_rect()
		var tooltip_size = character_tooltip_instance.size
		var offset = Vector2(15, 15)
		var target_pos = mouse_pos + offset

		# Adjust if off-screen
		if target_pos.x + tooltip_size.x > viewport_rect.size.x:
			target_pos.x = mouse_pos.x - tooltip_size.x - offset.x
		if target_pos.y + tooltip_size.y > viewport_rect.size.y:
			target_pos.y = mouse_pos.y - tooltip_size.y - offset.y

		character_tooltip_instance.global_position = target_pos
		character_tooltip_instance.show()

func _on_character_hover_exited(_character: CombatCharacter):
	if character_tooltip_instance:
		character_tooltip_instance.hide()


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
			var neighbour = HexHelper.hex_neighbor(hex, i)
			if cell_ids.has(neighbour):
				astar.connect_points(cell_ids[hex], cell_ids[neighbour], false)


func _on_skill_selected(skill) : 
	if characters[turn] is PlayerCombatCharacter : 
		(characters[turn] as PlayerCombatCharacter).highlight_skill(skill)
