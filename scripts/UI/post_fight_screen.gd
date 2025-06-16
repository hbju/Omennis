# PostFightScreen.gd
extends Control

@onready var title_label: Label = $background/borders/header/title_label
@onready var displays = [$background/character_result_display_1,
	$background/character_result_display_2,
	$background/character_result_display_3,
	$background/character_result_display_4]
@onready var background: TextureRect = $background
@onready var character_sheet_ui: Control = $character_sheet_ui
@onready var proceed_button: TextureButton = $background/proceed_button

func _ready():
	proceed_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	for i in range(4):
		displays[i].class_badge.pressed.connect(_on_show_skill_tree.bind(i))
		displays[i].class_badge.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	
	character_sheet_ui.character_sheet_closed.connect(background.show)

# Call this function from main_scene.gd to initialize the screen
func setup(party_before: Array[PartyMember], party_after: Array[PartyMember], xp_gained: Array[int], victory: bool):
	# Set Title
	background.show()
	character_sheet_ui.hide()
	title_label.text = "Victory!" if victory else "Defeat..." # Or "Combat Over"

	for i in range(4):
		if i >= party_after.size():
			displays[i].hide() # Hide unused displays
			continue

		var char_after = party_after[i]
		var char_before = party_before[i]
		var xp = xp_gained[i]

		# Update the display using before & after states
		displays[i].update_display(char_before, char_after, xp)
		displays[i].show() # Show the display

func _on_show_skill_tree(index: int):
	print("Showing skill tree for character at index: ", index)
	character_sheet_ui.show_sheet(displays[index].party_member)	
	background.hide()