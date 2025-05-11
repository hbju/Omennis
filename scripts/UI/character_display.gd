@tool
extends TextureRect
class_name Character_Display

@onready var infos_label = $infos
@onready var avatar_portrait = $avatar_background/avatar_portrait
@onready var delete_button = $delete_button
@onready var xp_bar = $infos/xp_bar
@onready var class_badge: TextureButton = $class_badge
@onready var class_badge_icon: TextureRect = $class_badge/class_icon

signal character_changed
signal fire_character
signal show_skill_tree

@export var show_delete_button: bool = true:
	set(value): 
		if delete_button :
			delete_button.visible = value
			delete_button.disabled = not value
		show_delete_button = value
@export var character_name: String = "Halfai":
	set(value):
		character_name = value
		update_values()
@export var character_class: String = "Rogue":
	set(value):
		character_class = value
		update_values()
@export var character_level: int = 1:
	set(value):
		character_level = value
		update_values()
@export var character_xp: int = 0:
	set(value):
		character_xp = value
		update_values()
@export var character_portrait: int = 1:
	set(value):
		character_portrait = value
		update_values()

var party_member: PartyMember

func _ready() : 
	delete_button.pressed.connect(_on_delete_button_pressed)
	delete_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))

	class_badge.pressed.connect(_on_class_badge_pressed)
	class_badge.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))

func update_values():
	if Engine.is_editor_hint():
		if infos_label :
			var char_class = party_member.CLASSES.Warrior if character_class == "Warrior" else party_member.CLASSES.Rogue if character_class == "Rogue" else party_member.CLASSES.Mage
			party_member = PartyMember.new(character_name, char_class, character_portrait, character_level, 0)
			party_member.character_experience = character_xp

			_update_infos()

			character_changed.emit()


func update_character(_party_member: PartyMember):
	self.party_member = _party_member
	
	_update_infos()
	
func _on_delete_button_pressed(): 
	fire_character.emit()

func _on_class_badge_pressed():
	show_skill_tree.emit()

func _update_infos():
	infos_label.text = party_member.character_name + "\n Lvl : " + str(party_member.character_level) + "\n XP : " + str(party_member.character_experience) + "/" + str(party_member.next_level())

	xp_bar.value = party_member.character_experience
	xp_bar.max_value = party_member.next_level()

	avatar_portrait.texture = load(party_member.get_portrait_path())

	class_badge_icon.texture = load("res://assets/ui/classes_icons/" + party_member.get_char_class().to_lower() + ".png")

