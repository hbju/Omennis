# MainMenu.gd
extends Control

# Get references to the buttons
@onready var campaign_button: TextureButton = $background/center_container/vbox_container/campaign_button
@onready var arena_button: TextureButton = $background/center_container/vbox_container/arena_button
@onready var options_button: TextureButton = $background/center_container/vbox_container/options_button
@onready var quit_button: TextureButton = $background/center_container/vbox_container/exit_button

func _ready():
	# Connect button signals to functions
	campaign_button.pressed.connect(_on_campaign_button_pressed)
	campaign_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	arena_button.pressed.connect(_on_arena_button_pressed)
	arena_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	options_button.pressed.connect(_on_options_button_pressed)
	options_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	quit_button.pressed.connect(_on_quit_button_pressed)
	quit_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))

	AudioManager.play_music(AudioManager.MAIN_MENU_MUSIC) # Play main menu music

	campaign_button.grab_focus()

func _on_campaign_button_pressed():
	var err = get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
	if err != OK:
		printerr("Error loading main scene: ", err)

func _on_arena_button_pressed():
	var err = get_tree().change_scene_to_file("res://scenes/arena_manager.tscn") 
	if err != OK:
		printerr("Error loading arena scene: ", err)

func _on_options_button_pressed():
	# TODO: Implement options screen or panel opening here
	# Example: $OptionsMenu.show() if you have an options menu node
	pass

func _on_quit_button_pressed():
	get_tree().quit()

# Optional: Allow quitting with the Escape key
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"): # ui_cancel is usually mapped to Escape
		get_tree().quit()
