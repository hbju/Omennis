extends Node2D
class_name ImpactEffect

@onready var animated_sprite: AnimatedSprite2D = $impact_animation
@onready var impact_player: AudioStreamPlayer2D = $impact_player

const LIGHTNING_STORM_IMPACT = preload("res://audio/sfx/skills/thunder_impact_heavy.mp3")
const METEOR_IMPACT = preload("res://audio/sfx/skills/explosion_impact_01.wav")

var impact_type: String = "" 

func set_impact_type(type_name: String):
	impact_type = type_name
	match type_name:
		"thunderstrike":
			animated_sprite.play("thunderstrike_4")
			impact_player.stream = METEOR_IMPACT
		"lightning_storm":
			animated_sprite.play("thunderstrike_1")
			impact_player.stream = LIGHTNING_STORM_IMPACT

	impact_player.play() # Play the sound effect
