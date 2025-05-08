# ArenaClassSelection.gd
extends Control

signal class_selected(selected_class: Character.CLASSES)

@onready var title_label: Label = $background/CenterContainer/content_vbox/title_label_bg/title_label
@onready var warrior_button: TextureButton = $background/CenterContainer/content_vbox/class_options_hbox/warrior_button
@onready var mage_button: TextureButton = $background/CenterContainer/content_vbox/class_options_hbox/mage_button
@onready var confirm_button: TextureButton = $background/CenterContainer/content_vbox/proceed_button

var chosen_class: Character.CLASSES = Character.CLASSES.None # Default to None or first class
var selected_button: TextureButton = null

func _ready():
	warrior_button.pressed.connect(_on_class_button_pressed.bind(Character.CLASSES.Warrior, warrior_button))
	mage_button.pressed.connect(_on_class_button_pressed.bind(Character.CLASSES.Mage, mage_button))
	# rogue_button.pressed.connect(_on_class_button_pressed.bind(Character.CLASSES.Rogue, rogue_button))
	confirm_button.pressed.connect(_on_confirm_button_pressed)

	# Start with no class selected and confirm button disabled
	confirm_button.disabled = true
	_highlight_selected_button(null) # Clear any initial highlight

func _on_class_button_pressed(class_enum_value: Character.CLASSES, button_node: TextureButton):
	chosen_class = class_enum_value
	selected_button = button_node

	_highlight_selected_button(button_node)
	confirm_button.disabled = false # Enable confirm button

func _highlight_selected_button(button_to_highlight: TextureButton):
	# Reset previous highlights (simple modulation example)
	warrior_button.modulate = Color.WHITE
	mage_button.modulate = Color.WHITE
	# rogue_button.modulate = Color.WHITE

	if button_to_highlight:
		button_to_highlight.modulate = Color.DIM_GRAY # Highlight the selected button

func _on_confirm_button_pressed():
	if chosen_class != Character.CLASSES.None:
		class_selected.emit(chosen_class)
		hide() # Hide the selection screen
	else:
		# Should not happen if button is disabled, but a good check
		printerr("No class selected to confirm!")

# Call this to show the screen
func prompt_class_selection():
	show()
	confirm_button.disabled = true
	chosen_class = Character.CLASSES.None
	_highlight_selected_button(null)
	# Optionally grab focus on the first class button
	if warrior_button: warrior_button.grab_focus()