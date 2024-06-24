extends Character
class_name PartyMember

var character_sex: SEX
var character_experience: int
var skill_points: int
var spent_skill_points: int

const NB_FEMALE_PORTRAIT = 36
const NB_MALE_PORTRAIT = 21

enum SEX {Male, Female, Other}

func _init(char_name, _class, portrait, level, sex, _skill_list: Array[Skill] = []):
	super(char_name, _class, portrait, level)
	self.character_sex = sex

	
static func new_rand() -> PartyMember: 
	var sex = randi_range(0, 1)
	var names = load("res://text/characters/" + ("female_character_names.json" if sex == 1 else "male_character_names.json")).data.names
	var char_name = names[randi() % names.size()]
	var portrait = randi() % (NB_FEMALE_PORTRAIT if sex == 1 else NB_MALE_PORTRAIT)
	
	return PartyMember.new(char_name, CLASSES.values()[randi_range(0, CLASSES.size() - 2)], portrait, 1, sex)
	
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
