@tool
extends TextureRect
class_name Character_Display

@onready var infos_label = $infos
@onready var avatar_portrait = $avatar_background/avatar_portrait
@onready var delete_button = $delete_button

signal character_changed
signal fire_character

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
@export var character_portrait: int = 1:
	set(value):
		character_portrait = value
		update_values()

var party_member: PartyMember

func _ready() : 
	delete_button.pressed.connect(_on_delete_button_pressed)

func update_values():
	if Engine.is_editor_hint():
		if infos_label :
			infos_label.text = character_name + ", " + character_class + "\n Lvl : " + str(character_level)
			var char_class = party_member.CLASSES.Warrior if character_class == "Warrior" else party_member.CLASSES.Rogue if character_class == "Rogue" else party_member.CLASSES.Mage
			party_member = PartyMember.new(character_name, char_class, character_portrait, character_level, 0)
			avatar_portrait.texture = load(party_member.get_portrait_path())

			character_changed.emit()


func update_character(_party_member: PartyMember):
	self.party_member = _party_member
	infos_label.text = party_member.character_name + ", " + party_member.CLASSES.keys()[party_member.character_class] + "\n Lvl : " + str(party_member.character_level)
	avatar_portrait.texture = load(party_member.get_portrait_path())
	
func _on_delete_button_pressed(): 
	fire_character.emit()
