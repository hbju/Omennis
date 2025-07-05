class_name Character

var character_name: String
var character_class: CLASSES
var character_portrait: int
var character_level: int

var _base_max_health: int
var _base_damage: float

var max_health: int
var damage: float
var init_shield: float

var crit_chance: float = 0.1 # Base 10% critical chance
var crit_damage_multiplier: float = 1.5 # Base +50% critical damage

var base_skill: Skill
var skill_list: Array[Skill] = []

enum CLASSES {Warrior, Mage, Rogue, None}

func _init(name, _class, portrait, level, base_health: int = 100, base_damage: float = 10):
	self.character_name = name
	self.character_class = _class
	self.character_portrait = portrait
	self.character_level = level
	self._base_max_health = base_health
	self.max_health = base_health
	self._base_damage = base_damage
	self.damage = base_damage

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