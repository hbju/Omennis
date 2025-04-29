class_name Character

var character_name: String
var character_class: CLASSES
var character_portrait: int
var character_level: int

var skill_list: Array[Skill] = []

enum CLASSES {Warrior, Mage, Rogue, None}

func _init(name, _class, portrait, level):
	self.character_name = name
	self.character_class = _class
	self.character_portrait = portrait
	self.character_level = level


func get_char_class() -> String : 
	return CLASSES.keys()[character_class]

func get_portrait_path() -> String : 
	return "res://assets/enemies/monster_" + "%02d" % character_portrait + ".png"

func duplicate() -> Character:
	var new_character = Character.new(character_name, character_class, character_portrait, character_level)
	new_character.skill_list = skill_list.duplicate(true)
	return new_character