extends CharacterBody2D
class_name FiresparkCombat

var move_target = null
@export var speed: int = 400
signal target_reached

func _ready():
	$firespark_animation.play()

func _physics_process(_delta):
	if not move_target: 
		return
	
	velocity = position.direction_to(move_target) * speed	
	if position.distance_to(move_target) > 100:
		move_and_slide()
	else :
		target_reached.emit()
		move_target = null
	
