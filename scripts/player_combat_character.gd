extends CombatCharacter
class_name PlayerCombatCharacter

const player_character = preload("res://scenes/player_combat_character.tscn")

var map: CombatMap
var is_turn = false



static func new_character(_char: Character) -> PlayerCombatCharacter:
	var new_char = player_character.instantiate()
	new_char.character = _char
	return new_char



func _ready():
	super()
	walkable_cells = [0, 2, 6, 7, 8, 9, 10, 11, 14, 15, 16]
	map = get_parent().get_parent().get_parent()


func take_turn() : 
	print("Player turn")
	is_turn = true
	map.highlight_neighbours(map.get_cell_coords(global_position))

func _input(event):
	if not is_turn: 
		return

	if event is InputEventMouseButton :
		print("Mouse click")
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var click_pos = map.get_cell_coords(get_global_mouse_position())
			var player_pos =  map.get_cell_coords(global_position)

			if map.is_neighbour(player_pos, click_pos) && map.can_walk(click_pos) && !map.cell_occupied(click_pos): 
				move_to(map.map_to_local(click_pos))
				is_turn = false
				map.reset_neighbours(map.get_cell_coords(global_position))

			var enemy = map.enemy_in_cell(click_pos)
			if map.is_neighbour(player_pos, click_pos) && enemy : 
				enemy.take_damage(damage)
				attack(map.to_local(enemy.global_position))
				is_turn = false
				map.reset_neighbours(map.get_cell_coords(global_position))
