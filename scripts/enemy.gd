class_name Enemy

var enemy_name: String
var enemy_class: CLASSES
var enemy_portrait: int
var enemy_level: int

enum CLASSES {Warrior, Rogue, Mage, None}

func _init(name, _class, portrait, level):
	self.enemy_name = name
	self.enemy_class = _class
	self.enemy_portrait = portrait
	self.enemy_level = level


func get_enemy_class() -> String : 
	return CLASSES.keys()[enemy_class]
