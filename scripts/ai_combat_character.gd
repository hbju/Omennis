extends CombatCharacter
class_name AICombatCharacter

var map: CombatMap
var player_units: Array
var attack_range: int = 1
var move_range: int = 1 # Number of tiles the enemy can move per turn

func _ready():
	walkable_cells = [0, 2, 6, 7, 8, 9, 10, 11, 14, 15, 16]
	map = get_parent().get_parent().get_parent()

func set_player_units(units):
	player_units = units

func take_turn():
	var closest_player_and_path = get_closest_player_path()
	var closest_player = closest_player_and_path[0]
	var path = closest_player_and_path[1]
	if closest_player:
		if path.size() > 2:
			print(path[1])
			move_to(map.map_to_local(path[1]))
		if path.size() == 2:
			attack(map.to_local(closest_player.global_position))
			closest_player.take_damage(damage)


func get_closest_player_path() -> Array:
	var closest_player = null
	var closest_path = null
	for player in player_units:
		var path = calculate_path_to_player(player)
		print(path)
		var distance = path.size()
		if  closest_path == null or distance < closest_path.size():
			closest_path = path
			closest_player = player
	return [closest_player, closest_path]

func calculate_path_to_player(player) -> PackedVector2Array:
	var enemy_tile_id = map.cell_ids[map.get_cell_coords(global_position)]
	var target_tile_id = map.cell_ids[map.get_cell_coords(player.global_position)]
	return map.astar.get_point_path(enemy_tile_id, target_tile_id)

	

