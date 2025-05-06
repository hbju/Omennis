extends CharacterBody2D
class_name ProjectileEffect

signal target_reached

@export var speed: float = 1500.0 # Pixels per second
@onready var travel_player: AudioStreamPlayer2D = $travel_player # If using loop
@onready var impact_player: AudioStreamPlayer2D = $impact_player

const TRAVEL_SFX = preload("res://audio/sfx/skills/magic_missile.wav") # Example loop
const IMPACT_SFX = [
	preload("res://audio/sfx/skills/small_spell_impact_01.wav"),
	preload("res://audio/sfx/skills/small_spell_impact_02.wav"),
	preload("res://audio/sfx/skills/small_spell_impact_03.wav"),
]
	

var target_position = Vector2i.ZERO

func _ready():
	# Set a max lifetime
	$Timer.wait_time = 6.0 
	$Timer.one_shot = true
	$Timer.timeout.connect(queue_free) 
	$Timer.start()

	travel_player.stream = TRAVEL_SFX; 
	travel_player.play()

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
		if not IMPACT_SFX.is_empty():
			impact_player.stream = IMPACT_SFX[randi() % IMPACT_SFX.size()]
			impact_player.play()
		target_reached.emit()
		target_position = null
