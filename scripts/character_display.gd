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

var character: Character

func _ready() : 
	delete_button.pressed.connect(_on_delete_button_pressed)

func update_values():
	if Engine.is_editor_hint():
		if infos_label :
			infos_label.text = character_name + ", " + character_class + "\n Lvl : " + str(character_level)
			avatar_portrait.texture = load("res://assets/chars/" + ("female/female_" if character.char_sex == 1 else "male/male_") + "%02d" % character_portrait + ".png")
			var char_class = Character.CLASSES.Warrior if character_class == "Warrior" else Character.CLASSES.Rogue if character_class == "Rogue" else Character.CLASSES.Mage
			character = Character.new(character_name, char_class, character_portrait, 0, character_level)
			character_changed.emit()


func update_character(character: Character):
	self.character = character
	infos_label.text = character.name + ", " + Character.CLASSES.keys()[character.char_class] + "\n Lvl : " + str(character.char_level)
	avatar_portrait.texture = load("res://assets/chars/"  + ("female/female_" if character.char_sex == 1 else "male/male_") + "%02d"  % character.char_portrait + ".png")
	
func _on_delete_button_pressed(): 
	fire_character.emit()
