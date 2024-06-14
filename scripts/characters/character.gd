class_name Character

var character_name: String
var character_class: CLASSES
var character_portrait: int
var character_level: int

enum CLASSES {Warrior, Rogue, Mage, None}

func _init(name, _class, portrait, level):
	self.character_name = name
	self.character_class = _class
	self.character_portrait = portrait
	self.character_level = level


func get_char_class() -> String : 
	return CLASSES.keys()[character_class]

func get_portrait_path() -> String : 
	return "res://assets/enemies/monster_" + "%02d" % character_portrait + ".png"
