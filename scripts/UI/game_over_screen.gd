# GameOverScreen.gd
extends Control

signal retry_arena_pressed
signal main_menu_pressed

@onready var game_over_title_label: Label = $background/CenterContainer/content_vbox/title_label_bg/title_label # Adjust path
@onready var stats_label: Label = $background/CenterContainer/content_vbox/stats_vbox/stats_label # Adjust path
@onready var final_skills: Array[TextureRect] = [
	$background/CenterContainer/content_vbox/stats_vbox/final_skills/skill_1/skill_icon,
	$background/CenterContainer/content_vbox/stats_vbox/final_skills/skill_2/skill_icon,
	$background/CenterContainer/content_vbox/stats_vbox/final_skills/skill_3/skill_icon
] 
@onready var retry_button: TextureButton = $background/CenterContainer/content_vbox/actions_hbox/retry_button # Adjust path
@onready var main_menu_button: TextureButton = $background/CenterContainer/content_vbox/actions_hbox/main_menu_button # Adjust path

func _ready():
	retry_button.pressed.connect(_on_retry_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	hide() # Start hidden

func show_screen(wave_reached: int, character: Character):
	stats_label.text = "Wave Reached: %d\nFinal Skills :" % wave_reached

	for i in range(3):
		if i < character.skill_list.size():
			final_skills[i].texture = character.skill_list[i].get_skill_icon()
		else:
			final_skills[i].hide()

	show()
	retry_button.grab_focus() # Focus the retry button

func _on_retry_button_pressed():
	retry_arena_pressed.emit()
	hide()

func _on_main_menu_button_pressed():
	main_menu_pressed.emit()
	hide()