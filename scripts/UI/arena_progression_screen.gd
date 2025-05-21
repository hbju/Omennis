# ArenaProgressionScreen.gd
extends Control # Or PanelContainer

signal view_skills_pressed
signal next_wave_pressed

@onready var title_label: Label = $background/borders/header/title_label
@onready var display: TextureRect = $background/character_result_display
@onready var display_class_icon: TextureRect = $background/character_result_display/hbox/class_badge/class_icon
@onready var view_skills_button: TextureButton = $background/character_result_display/hbox/class_badge
@onready var next_wave_button: TextureButton = $background/proceed_button

var class_button_glowing: bool = false
var level_up: bool = false

func setup(character_before: PartyMember, character_after: PartyMember, xp_gained: int):
	title_label.text = "Wave %d Cleared!" % character_after.character_level # Or pass wave num
	level_up = character_after.skill_points > 0

	display.update_display(character_before, character_after, xp_gained)
	display_class_icon.texture = load("res://assets/ui/classes_icons/" + character_after.get_char_class().to_lower() + ".png")

	next_wave_button.disabled = character_after.skill_points > 0

func _ready():
	view_skills_button.pressed.connect(func (): view_skills_pressed.emit())
	view_skills_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))

	next_wave_button.pressed.connect(func (): next_wave_pressed.emit())
	next_wave_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	hide() 

func _process(delta):
	if level_up:
			if class_button_glowing:
				display_class_icon.modulate.b -= clamp(delta * 2, 0, 1)
				if display_class_icon.modulate.b <= 0:
					class_button_glowing = false
			else:
				display_class_icon.modulate.b += clamp(delta * 2, 0, 1)
				if display_class_icon.modulate.b >= 1:
					class_button_glowing = true

	else:
		display_class_icon.modulate = Color(1, 1, 1, 1)