# PostFightScreen.gd
extends Control

@onready var title_label: Label = $background/borders/header/title_label # Adjust path
@onready var char_1: TextureRect = $background/character_result_display_1
@onready var char_2: TextureRect = $background/character_result_display_2
@onready var char_3: TextureRect = $background/character_result_display_3
@onready var char_4: TextureRect = $background/character_result_display_4
@onready var proceed_button: TextureButton = $background/proceed_button

# Call this function from main_scene.gd to initialize the screen
func setup(party_before: Array[PartyMember], party_after: Array[PartyMember], xp_gained: int, victory: bool):
	# Set Title
	title_label.text = "Victory!" if victory else "Defeat..." # Or "Combat Over"

	var displays: Array[TextureRect] = [char_1, char_2, char_3, char_4]

	for i in range(4):
		if i >= party_after.size():
			displays[i].hide() # Hide unused displays
			continue

		var char_after = party_after[i]
		var char_before = party_before[i]

		# Update the display using before & after states
		displays[i].update_display(char_before, char_after, xp_gained)
