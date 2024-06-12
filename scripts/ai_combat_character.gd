extends CombatCharacter
class_name AICombatCharacter

var tilemap: TileMap
var player_units: Array
var attack_range: int = 1
var move_range: int = 2 # Number of tiles the enemy can move per turn

var astar: AStar2D = AStar2D.new()

func _ready():
	tilemap = get_node("/root/map") # Adjust the path to your TileMap node
	player_units = get_parent().get_node("player_characters").get_children() # Fill this with references to your player units

	setup_astar()

func perform_turn():
	var closest_player = get_closest_player()
	if closest_player:
		var path = calculate_path_to_player(closest_player)
		if path.size() > 0:
			move_towards_player(path)
			if is_within_attack_range(closest_player):
				attack(closest_player)

func get_closest_player():
	var min_distance = INF
	var closest_player = null
	for player in player_units:
		var distance = tile_distance_to(player.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_player = player
	return closest_player

func calculate_path_to_player(player):
	var start = tilemap.world_to_map(global_position)
	var end = tilemap.world_to_map(player.global_position)
	return astar.get_point_path(start, end)

func setup_astar():
	for x in range(tilemap.get_used_rect().size.x):
		for y in range(tilemap.get_used_rect().size.y):
			var id = tilemap.get_cell(x, y)
			if id != - 1: # Assuming -1 is an invalid tile
				astar.add_point(tilemap.map_to_world(Vector2(x, y)), Vector2(x, y))
				if x > 0 and astar.has_point(tilemap.map_to_world(Vector2(x - 1, y))):
					astar.connect_points(tilemap.map_to_world(Vector2(x, y)), tilemap.map_to_world(Vector2(x - 1, y)))
				if y > 0 and astar.has_point(tilemap.map_to_world(Vector2(x, y - 1))):
					astar.connect_points(tilemap.map_to_world(Vector2(x, y)), tilemap.map_to_world(Vector2(x, y - 1)))

func move_towards_player(path):
	if path.size() > move_range:
		path = path.slice(0, move_range + 1)
	for i in range(1, path.size()):
		move_to(path[i])

func is_within_attack_range(player):
	return tile_distance_to(player.global_position) <= attack_range

func tile_distance_to(cell):
	var enemy_tile = tilemap.world_to_map(global_position)
	var target_tile = tilemap.world_to_map(cell)
	return enemy_tile.distance_to(target_tile)

