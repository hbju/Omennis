extends CharacterBody2D

var target = null
@export var speed = 800
signal target_reached

func move_to(new_target) : 
	if not target :
		target = new_target

func _physics_process(_delta):
	if not target : 
		return
	velocity = position.direction_to(target) * speed
	if position.distance_to(target) > 50:
		move_and_slide()
	else :
		target_reached.emit()
		target = null

func toggle_camera(focus: bool = false) : 
	$Camera2D.enabled = focus
