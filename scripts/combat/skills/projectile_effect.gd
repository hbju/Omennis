extends CharacterBody2D
class_name ProjectileEffect

signal target_reached

@export var speed: float = 1500.0 # Pixels per second

var target_position = Vector2i.ZERO

func _ready():
	# Set a max lifetime
	$Timer.wait_time = 6.0 
	$Timer.one_shot = true
	$Timer.timeout.connect(queue_free) 
	$Timer.start()

	$projectile_animation.play()

func set_target_position(global_pos: Vector2i):
	target_position = global_pos
	rotation = position.direction_to(target_position).angle()

func _physics_process(_delta):
	if not target_position: 
		return
	
	velocity = position.direction_to(target_position) * speed	
	if position.distance_to(target_position) > 100:
		move_and_slide()
	else :
		target_reached.emit()
		target_position = null
