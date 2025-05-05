extends CharacterBody2D

var target = null

@export var speed = 800
@onready var footstep_player: AudioStreamPlayer2D = $footstep_player
const FOOTSTEP_SFX = [
	preload("res://audio/sfx/character/footstep_dirt_01.wav"),
	preload("res://audio/sfx/character/footstep_dirt_02.wav"),
]

signal target_reached

func move_to(new_target) : 
	if not target :
		if not FOOTSTEP_SFX.is_empty():
			footstep_player.stream = FOOTSTEP_SFX[randi() % FOOTSTEP_SFX.size()]
			footstep_player.play()
		target = new_target

func _physics_process(_delta):
	if not target : 
		return
	velocity = position.direction_to(target) * speed
	if position.distance_to(target) > 50:
		move_and_slide()
	else :
		position = target
		target_reached.emit()
		target = null

func toggle_camera(focus: bool = false) : 
	$Camera2D.enabled = focus
