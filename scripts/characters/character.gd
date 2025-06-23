class_name Character

var character_name: String
var character_class: CLASSES
var character_portrait: int
var character_level: int

var max_health: int
var base_damage: float
var crit_chance: float = 0.1 # Base 10% critical chance
var crit_damage_multiplier: float = 1.5 # Base +50% critical damage

var base_skill: Skill
var skill_list: Array[Skill] = []

enum CLASSES {Warrior, Mage, Rogue, None}

func _init(name, _class, portrait, level, health: int = 100, damage: float = 10):
	self.character_name = name
	self.character_class = _class
	self.character_portrait = portrait
	self.character_level = level
	self.max_health = health
	self.base_damage = damage

	if _class == CLASSES.Warrior:
		self.base_skill = BoundingLeap.new()
	elif _class == CLASSES.Mage:
		self.base_skill = FiresparkMage.new()
	elif _class == CLASSES.Rogue:
		self.base_skill = ShadowStep.new()

func reset_skills(): 
	for skill in skill_list:
		skill.cooldown = 0
	if base_skill:
		base_skill.cooldown = 0

func get_char_class() -> String : 
	return CLASSES.keys()[character_class]

func get_portrait_path() -> String : 
	return "res://assets/enemies/monster_" + "%02d" % character_portrait + ".png"

func duplicate() -> Character:
	var new_character = Character.new(character_name, character_class, character_portrait, character_level)
	new_character.skill_list = skill_list.duplicate(true)
	return new_character