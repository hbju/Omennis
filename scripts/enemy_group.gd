class_name EnemyGroup

var name: String
var enemies_class: CLASSES
var enemies_portrait: int
var enemies_count: int
var level: int

enum CLASSES {Warrior, Rogue, Mage, None}

func _init(name, enemies_class, enemies_portrait, enemies_count, enemies_level):
	self.name = name
	self.enemies_class = enemies_class
	self.enemies_portrait = enemies_portrait
	self.enemies_count = enemies_count
	self.level = enemies_level
	
func get_enemy_group_class() : 
	return CLASSES.keys()[enemies_class]
