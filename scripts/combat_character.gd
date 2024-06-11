extends CharacterBody2D

var target = null
@export var speed: int = 800
signal target_reached

@onready var health_bar = $health_bar
signal character_died(character)

var health: float = 100
var max_health: float = 100
var damage: float = 10

func move_to(new_target) : 
	print("move_to")
	if not target :
		target = new_target

func _physics_process(delta):
	if not target : 
		return
	velocity = position.direction_to(target) * speed
	if position.distance_to(target) > 50:
		move_and_slide()
	else :
		target_reached.emit()
		target = null

func take_damage(damage_taken) :
	health -= damage_taken
	health_bar.value = (health / max_health) * health_bar.max_value
	if health <= 0 :
		queue_free()
		character_died.emit(self)

