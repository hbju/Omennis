# ArenaProgressionScreen.gd
extends Control # Or PanelContainer

signal view_skills_pressed
signal next_wave_pressed

@onready var title_label: Label = $background/borders/header/title_label
@onready var display: TextureRect = $background/character_result_display
@onready var display_class_button: TextureButton = $background/character_result_display/hbox/skill_button
@onready var view_skills_button: TextureButton = $background/character_result_display/hbox/skill_button
@onready var next_wave_button: TextureButton = $background/proceed_button


func setup(character_before: PartyMember, character_after: PartyMember, xp_gained: int):
	title_label.text = "Wave %d Cleared!" % character_after.character_level # Or pass wave num

	display.update_display(character_before, character_after, xp_gained)
	display_class_button.texture_normal = load("res://assets/ui/classes_icons/" + character_after.get_char_class().to_lower() + ".png")


	# Show/hide skill button based on available points
	view_skills_button.visible = (character_after.skill_points > 0)
	view_skills_button.disabled = not view_skills_button.visible

func _ready():
	view_skills_button.pressed.connect(func (): view_skills_pressed.emit())
	next_wave_button.pressed.connect(func (): next_wave_pressed.emit())
	hide() 