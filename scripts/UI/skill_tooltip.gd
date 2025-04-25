# SkillTooltip.gd
extends PanelContainer

@onready var skill_name_label: Label = $VBoxContainer/SkillNameLabel
@onready var skill_description_label: Label = $VBoxContainer/SkillDescriptionLabel

func update_content(skill: Skill):
	if not skill:
        # Handle cases where skill might be null, maybe hide?
		skill_name_label.text = "???"
		skill_description_label.text = "No skill data."
		return

	skill_name_label.text = skill.get_skill_name()
	skill_description_label.text = skill.get_skill_description()

func _ready():
    # Ensure it starts hidden
	reset_size()
	hide()