extends Character
class_name PartyMember

var character_sex: SEX
var character_experience: int
var skill_points: int
var spent_skill_points: int

const NB_FEMALE_PORTRAIT = 36
const NB_MALE_PORTRAIT = 21

enum SEX {Male, Female, Other}

func _init(char_name, _class, portrait, level, sex, _skill_list: Array[Skill] = [], health: int = 100, damage: float = 10):
	super(char_name, _class, portrait, level, health, damage)
	self.character_sex = sex

	
static func new_rand() -> PartyMember: 
	var sex = randi_range(0, 1)
	var names = load("res://text/characters/" + ("female_character_names.json" if sex == 1 else "male_character_names.json")).data.names
	var char_name = names[randi() % names.size()]
	var portrait = randi() % (NB_FEMALE_PORTRAIT if sex == 1 else NB_MALE_PORTRAIT)
	var char_class: CLASSES = CLASSES.values()[randi_range(0, CLASSES.size() - 3)]
	var char_init_skill: Array[Skill] = []
	match char_class:
		CLASSES.Warrior:
			char_init_skill.append(Charge.new())
			# char_init_skill.append(DefensiveStance.new())
		CLASSES.Mage:
			char_init_skill.append(FiresparkMage.new())
			# char_init_skill.append(ArcaneShield.new())

	var new_char = PartyMember.new(char_name, char_class, portrait, 1, sex)
	new_char.skill_list = char_init_skill
	
	return new_char
	
func receive_experience(experience: int) : 
	var threshold = next_level()
	character_experience += experience
	while character_experience > threshold : 
		character_level += 1
		skill_points += 1
		character_experience -= threshold
		threshold = next_level()

func spend_skill_point() : 
	if skill_points > 0 : 
		skill_points -= 1
		spent_skill_points += 1
	
func next_level() : 
	return floor(1000 * pow(character_level, 1.5))

func get_portrait_path() -> String : 
	return "res://assets/chars/" + ("female/female_" if character_sex == 1 else "male/male_") + "%02d" % character_portrait + ".png"

func _to_string():
	return "Name: " + character_name + "\n" + \
		"Class: " + get_char_class() + "\n" + \
		"Level: " + str(character_level) + "\n" + \
		"Experience: " + str(character_experience) + "\n" + \
		"Skill Points: " + str(skill_points) + "\n" + \
		"Spent Skill Points: " + str(spent_skill_points) + "\n"

func duplicate() -> PartyMember:
	var new_character = PartyMember.new(character_name, character_class, character_portrait, character_level, character_sex)
	new_character.skill_list = skill_list.duplicate(true)
	new_character.character_experience = character_experience
	new_character.skill_points = skill_points
	new_character.spent_skill_points = spent_skill_points
	return new_character
