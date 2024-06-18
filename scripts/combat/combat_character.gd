extends CharacterBody2D
class_name CombatCharacter

var map: CombatMap

var move_target = null
var attack_target = null
var init_pos = null
@export var speed: int = 600
signal turn_finished

@onready var health_bar = $health_bar
@onready var character_portrait = $character_portrait_bg/character_portrait
signal character_died(character)

var character: Character

var health: float = 100
var max_health: float = 100
var damage: float = 50

var walkable_cells: Array[int] = []

func _ready() : 
	map = get_parent().get_parent().get_parent()
	character_portrait.texture = load(character.get_portrait_path())


func move_to(new_target) : 
	if not move_target :
		move_target = new_target



func attack(new_target: Vector2i, ranged: bool = false) :
	if not attack_target :
		attack_target = new_target
		if ranged : 
			init_pos = position
		else : 
			var path = _calculate_path_to_character(map.local_to_map(new_target))
			init_pos = map.map_to_local(path[path.size() - 2])



func _physics_process(_delta):
	if not move_target and not attack_target : 
		return

	if move_target :	
		move_to_target()
	elif attack_target :
		move_to_attack_target()




func move_to_target() :
	velocity = position.direction_to(move_target) * speed
	if position.distance_to(move_target) > 50:
		move_and_slide()
	else :
		finish_turn()




func move_to_attack_target() :		
	z_index = 10
	velocity = position.direction_to(attack_target) * speed
	if position.distance_to(attack_target) > 50:
		move_and_slide()
	else :
		if init_pos :
			attack_target = init_pos
			init_pos = null
		else :
			finish_turn()




func take_damage(damage_taken) :
	health -= damage_taken
	health_bar.value = (health / max_health) * health_bar.max_value
	if health <= 0 :
		queue_free()
		character_died.emit(self)




func take_turn() : 
	assert(false, "take_turn not implemented")

func finish_turn() : 
	z_index = 0
	attack_target = null
	move_target = null
	turn_finished.emit()

func _calculate_path_to_character(other_char_pos: Vector2i) -> PackedVector2Array:
	var this_tile_id = map.cell_ids[map.get_cell_coords(global_position)]
	var target_tile_id = map.cell_ids[other_char_pos]
	return map.astar.get_point_path(this_tile_id, target_tile_id)

