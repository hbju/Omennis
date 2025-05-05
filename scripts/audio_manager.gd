# AudioManager.gd
extends Node

var music_player: AudioStreamPlayer
var ui_sfx_player: AudioStreamPlayer


const MAIN_MENU_MUSIC = preload("res://audio/music/main_menu_music.wav")
const OVERWORLD_MUSIC = [
	preload("res://audio/music/overworld_music_1.wav"),
	preload("res://audio/music/overworld_music_2.wav"),
]
const BATTLE_MUSIC = [
	preload("res://audio/music/battle_music_1.wav"),
	preload("res://audio/music/battle_music_2.wav")
]
const ARENA_MUSIC = BATTLE_MUSIC
const VICTORY_STINGER = preload("res://audio/music/victory_music.wav")
const DEFEAT_STINGER = preload("res://audio/music/defeat_music.wav")

const UI_BUTTON_CLICK = preload("res://audio/sfx/ui/button_click.wav") 
const UI_SKILL_UNLOCK = preload("res://audio/sfx/ui/skill_unlock.wav") 
const UI_SCREEN_OPEN = preload("res://audio/sfx/ui/panel_open.wav") 
const UI_HOVERING = preload("res://audio/sfx/ui/hovering.wav")
const UI_CANCEL_ACTION = preload("res://audio/sfx/ui/cancel.wav")
const UI_ENTER_COMBAT = preload("res://audio/sfx/ui/enter_combat.wav")

var current_music: AudioStream = null

func _ready():
	# Create the music player node
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player) 

	ui_sfx_player = AudioStreamPlayer.new()
	ui_sfx_player.name = "UISFXPlayer"
	ui_sfx_player.bus = "UI SFX"
	add_child(ui_sfx_player)

# Function to play music, optionally choosing randomly from a list
func play_music(music_resource: Variant, random_from_list: bool = false):
	var track_to_play: AudioStream = null

	if music_resource is Array and random_from_list:
		if not music_resource.is_empty():
			track_to_play = music_resource[randi() % music_resource.size()]
	elif music_resource is AudioStream:
		track_to_play = music_resource

	if track_to_play and track_to_play != current_music:
		music_player.stream = track_to_play
		music_player.play()
		current_music = track_to_play
	elif track_to_play == current_music and not music_player.playing:
		# Resume if same track was paused/stopped
		music_player.play()

func stop_music():
	print("AudioManager: Stopping music")
	music_player.stop()
	current_music = null # Clear current track

# Function for short one-off sounds like victory/defeat
func play_stinger(stinger_resource: AudioStream):
	if stinger_resource:
		stop_music()
		music_player.stream = stinger_resource
		music_player.play()

func play_sfx(sfx_resource: AudioStream):
	if sfx_resource and ui_sfx_player:
		ui_sfx_player.stream = sfx_resource
		ui_sfx_player.play()

func set_music_volume(volume_db: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volume_db)

func set_sfx_volume(volume_db: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volume_db)