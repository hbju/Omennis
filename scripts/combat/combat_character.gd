extends CharacterBody2D
class_name CombatCharacter

var move_target = null
var attack_target = null
var init_pos = null
@export var speed: int = 600
signal target_reached

@onready var health_bar = $health_bar
@onready var character_portrait = $character_portrait_bg/character_portrait
signal character_died(character)

var character: Character

var health: float = 100
var max_health: float = 100
var damage: float = 50

var walkable_cells: Array[int] = []

func _ready() : 
	character_portrait.texture = load(character.get_portrait_path())


func move_to(new_target) : 
	if not move_target :
		move_target = new_target



func attack(new_target) :
	if not attack_target :
		attack_target = new_target
		init_pos = position




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
		target_reached.emit()
		move_target = null




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
			z_index = 0
			target_reached.emit()
			attack_target = null




func take_damage(damage_taken) :
	health -= damage_taken
	health_bar.value = (health / max_health) * health_bar.max_value
	if health <= 0 :
		queue_free()
		character_died.emit(self)




func take_turn() : 
	assert(false, "take_turn not implemented")

