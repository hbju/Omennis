class_name Character

var name: String
var char_class: CLASSES
var char_portrait: int
var char_sex: SEX
var char_level: int
var character_experience: int

const NB_FEMALE_PORTRAIT = 36
const NB_MALE_PORTRAIT = 21

enum CLASSES {Warrior, Rogue, Mage}
enum SEX {Male, Female, Other}

func _init(char_name, _class, portrait, sex, level):
	self.name = char_name
	self.char_class = _class
	self.char_portrait = portrait
	self.char_sex = sex
	self.char_level = level
	
static func new_rand() : 
	var sex = randi_range(0, 1)
	var names = load("res://text/characters/" + ("female_character_names.json" if sex == 1 else "male_character_names.json")).data.names
	var char_name = names[randi() % names.size()]
	var portrait = randi() % (NB_FEMALE_PORTRAIT if sex == 1 else NB_MALE_PORTRAIT)
	
	return Character.new(char_name, CLASSES.values()[randi_range(0, CLASSES.size() - 1)], portrait, sex, 1)

func get_char_class() : 
	return CLASSES.keys()[char_class]
	
func receive_experience(experience: int) : 
	var threshold = next_level()
	print(str(threshold) + " " + str(experience))
	character_experience += experience
	if character_experience > threshold : 
		char_level += 1
		character_experience -= threshold
	
func next_level() : 
	return floor(1000 * pow(char_level, 1.5))
