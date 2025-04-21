extends Node2D
class_name ImpactEffect

@onready var animated_sprite: AnimatedSprite2D = $impact_animation
# @onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var impact_type: String = "" 

func set_impact_type(type_name: String):
	impact_type = type_name
	match type_name:
		"thunderstrike":
			animated_sprite.play("thunderstrike_4")
			# audio_player.stream = load("res://assets/audio/thunder_impact.wav")
		"lightning_storm":
			animated_sprite.play("thunderstrike_1")
			# audio_player.stream = load("res://assets/audio/meteor_impact.wav")

	# audio_player.play() # Play the sound effect
