extends TextureRect

@onready var portrait: TextureRect = $hbox/portrait/avatar_portrait
@onready var name_label: Label = $hbox/info_vbox/name_label
@onready var xp_gain_label: Label = $hbox/info_vbox/xp_gain_label
@onready var xp_progress_label: Label = $hbox/info_vbox/xp_progress_label
@onready var skill_point_available_label: Label = $hbox/info_vbox/skill_points_available_label

func update_display(character_before: PartyMember, character_after: PartyMember, xp_gained: int):
	if not character_after: # Should always have the 'after' state
		printerr("CharacterResultDisplay requires character_after data!")
		queue_free() # Remove self if data is bad
		return

	name_label.text = character_after.character_name
	portrait.texture = load(character_after.get_portrait_path())
	xp_gain_label.text = "+%d XP" % xp_gained

	var leveled_up = false
	if character_before and character_after.character_level > character_before.character_level:
		leveled_up = true
		xp_gain_label.text += "(Level Up! (Lv. %d -> Lv. %d))" % [character_before.character_level, character_after.character_level]

	xp_progress_label.text = "XP: %d / %d" % [character_after.character_experience, character_after.next_level()]

	var skill_points_gained = 0
	var new_skill_point = ""
	if character_before and character_after.skill_points > character_before.skill_points:
		if leveled_up:
			skill_points_gained = character_after.skill_points - character_before.skill_points # Calculate diff
			# Assuming 1 point per level for now
			new_skill_point = "(+%d!)" % skill_points_gained


	skill_point_available_label.text = "Skill Points Available: %d" % character_after.skill_points + new_skill_point
