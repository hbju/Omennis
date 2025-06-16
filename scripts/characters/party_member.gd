extends Character
class_name PartyMember

var character_unique_id: String
var character_sex: SEX
var character_experience: int
var skill_points: int
var spent_skill_points: int

var unlocked_skills: Array[String] = []

var non_combat_stats: Dictionary = {
	"Perception": 1,
	"Charisma": 1,
	"Lore": 1,
	"Survival": 1,
	"Logistics": 1
}
var unspent_non_combat_stat_points: int = 0

var personality_traits: Dictionary = {
	"Valor": 0,     # -5 (Timid) to +5 (Brave)
	"Temper": 0,    # -5 (Cautious) to +5 (Impulsive)
	"Ethics": 0,    # -5 (Self-Serving) to +5 (Altruistic)
	"Worldview": 0  # -5 (Cynical) to +5 (Faithful)
}

enum RELATIONSHIP_TRACK { FRIENDSHIP, RIVALRY, RESPECT, TRUST, ATTRACTION, FEAR }
var relationships: Dictionary = {} 

const NB_FEMALE_PORTRAIT = 36
const NB_MALE_PORTRAIT = 21

enum SEX {Male, Female, Other}

func _init(char_name, _class, portrait, level, sex, 
		skills: Array[Skill] = [], 
		health: int = 100, damage: float = 10,
		initial_non_combat_stats: Dictionary = {},
		initial_trait_scores: Dictionary = {}):
	super(char_name, _class, portrait, level, health, damage)

	character_unique_id = char_name + str(Time.get_unix_time_from_system()) + str(randi())	

	self.character_sex = sex
	
	for skill in skills:
		self.skill_list.append(skill)

	if not initial_non_combat_stats.is_empty():
		for key in initial_non_combat_stats:
			if non_combat_stats.has(key):
				non_combat_stats[key] = initial_non_combat_stats[key]
	else:
		# Default random assignment if not provided
		var starting_points = 4 + (level - 1) * 2 
		var stat_keys = non_combat_stats.keys()
		for _i in range(starting_points):
			non_combat_stats[stat_keys[randi() % stat_keys.size()]] += 1

	if not initial_trait_scores.is_empty():
		for key in initial_trait_scores:
			if personality_traits.has(key):
				personality_traits[key] = initial_trait_scores[key]
	else:
		# Default: start two traits at -1/+1, rest at 0
		var keys = personality_traits.keys()
		var first_trait = keys[randi() % keys.size()]
		var second_trait = keys[randi() % keys.size()]
		while second_trait == first_trait:
			second_trait = keys[randi() % keys.size()]
		personality_traits[first_trait] = -1 if randi() % 2 == 0 else 1
		personality_traits[second_trait] = -1 if randi() % 2 == 0 else 1
		for key in keys:
			if key != first_trait and key != second_trait:
				personality_traits[key] = 0
	
static func new_rand(char_class: Character.CLASSES = Character.CLASSES.None) -> PartyMember: 
	var sex = randi_range(0, 1)
	var names = load("res://text/characters/" + ("female_character_names.json" if sex == 1 else "male_character_names.json")).data.names
	var char_name = names[randi() % names.size()]
	var portrait = randi() % (NB_FEMALE_PORTRAIT if sex == 1 else NB_MALE_PORTRAIT)
	char_class = CLASSES.values()[randi_range(0, CLASSES.size() - 3)] if char_class == Character.CLASSES.None else char_class

	var new_char = PartyMember.new(char_name, char_class, portrait, 1, sex)
	
	return new_char
	
func receive_experience(experience: int) : 
	var threshold = next_level()
	character_experience += experience
	while character_experience > threshold : 
		character_level += 1
		skill_points += 1
		unspent_non_combat_stat_points += 2
		max_health += round(0.2 * max_health * randf_range(0.9, 1.1))
		base_damage += round(0.1 * base_damage * randf_range(0.9, 1.1))
		character_experience -= threshold
		threshold = next_level()

func spend_skill_point() : 
	if skill_points > 0 : 
		skill_points -= 1
		spent_skill_points += 1
	
func spend_non_combat_stat_point(stat_name: String) -> bool:
	if unspent_non_combat_stat_points > 0 and non_combat_stats.has(stat_name):
		non_combat_stats[stat_name] += 1
		unspent_non_combat_stat_points -= 1
		print("%s increased to %d" % [stat_name, non_combat_stats[stat_name]])
		return true
	print("Cannot spend point on %s. Points available: %d" % [stat_name, unspent_non_combat_stat_points])
	return false

func adjust_personality_trait(trait_name: String, amount: int) -> bool:
	if personality_traits.has(trait_name):
		personality_traits[trait_name] += amount
		personality_traits[trait_name] = clamp(personality_traits[trait_name], -5, 5)
		return true
	return false

func get_relationship_track_score(other_char_id: String, track: RELATIONSHIP_TRACK) -> float:
	if relationships.has(other_char_id) and relationships[other_char_id].has(track):
		return relationships[other_char_id][track]
	return 0.0
	
func adjust_relationship_track_score(other_char_id: String, track: RELATIONSHIP_TRACK, amount: float):
	if not relationships.has(other_char_id):
		relationships[other_char_id] = {
			  RELATIONSHIP_TRACK.FRIENDSHIP: 50.0,
			  RELATIONSHIP_TRACK.RIVALRY: 0.0,
			  RELATIONSHIP_TRACK.RESPECT: 50.0,
			  RELATIONSHIP_TRACK.TRUST: 50.0,
			  RELATIONSHIP_TRACK.ATTRACTION: 0.0,
			  RELATIONSHIP_TRACK.FEAR: 0.0
		}
	  
	var current_score = relationships[other_char_id].get(track, 0.0)
	var max_score = 100.0 if track in [RELATIONSHIP_TRACK.FRIENDSHIP, RELATIONSHIP_TRACK.RESPECT, RELATIONSHIP_TRACK.TRUST] else 50.0
	var new_score = clamp(current_score + amount, 0, max_score) # Clamp between 0 and 100 for these tracks
	relationships[other_char_id][track] = new_score
	print("%s's %s with %s changed by %s to %s" % [character_name, RELATIONSHIP_TRACK.keys()[track], other_char_id, amount, new_score])
	
func get_derived_relationship_name(other_member: PartyMember) -> String:
	var relationship_tracks = relationships.get(other_member.character_unique_id, {
		RELATIONSHIP_TRACK.FRIENDSHIP: 50.0,
		RELATIONSHIP_TRACK.RIVALRY: 0.0,
		RELATIONSHIP_TRACK.RESPECT: 50.0,
		RELATIONSHIP_TRACK.TRUST: 50.0,
		RELATIONSHIP_TRACK.ATTRACTION: 0.0,
		RELATIONSHIP_TRACK.FEAR: 0.0
	})
	var friend = relationship_tracks.get(PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, 50)
	var respect = relationship_tracks.get(PartyMember.RELATIONSHIP_TRACK.RESPECT, 50)
	var trust = relationship_tracks.get(PartyMember.RELATIONSHIP_TRACK.TRUST, 50)
	var rival = relationship_tracks.get(PartyMember.RELATIONSHIP_TRACK.RIVALRY, 0)
	var attract = relationship_tracks.get(PartyMember.RELATIONSHIP_TRACK.ATTRACTION, 0)
	var fear = relationship_tracks.get(PartyMember.RELATIONSHIP_TRACK.FEAR, 0)

	var _other_friend = other_member.get_relationship_track_score(character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP)
	var _other_rival = other_member.get_relationship_track_score(character_unique_id, PartyMember.RELATIONSHIP_TRACK.RIVALRY)
	var other_respect = other_member.get_relationship_track_score(character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT)
	var other_trust = other_member.get_relationship_track_score(character_unique_id, PartyMember.RELATIONSHIP_TRACK.TRUST)
	var _other_attract = other_member.get_relationship_track_score(character_unique_id, PartyMember.RELATIONSHIP_TRACK.ATTRACTION)
	var other_fear = other_member.get_relationship_track_score(character_unique_id, PartyMember.RELATIONSHIP_TRACK.FEAR)

	if friend >= 80 and attract >= 35 and respect >= 60 and trust >= 60: return "Soulmates"
	if friend >= 70 and respect >= 60 and trust >= 60: return "Trusted Comrades"
	if friend >= 75 and rival >= 20: return "Friendly Rivals"
	if friend <= 30 and rival >= 25 and trust <= 25: return "Bitter Rivals"
	if fear >= 25 and respect >= 65 and other_member.level > character_level : return "Feared Leader"
	if other_fear >= 25 and other_respect >= 65 and character_level > other_member.character_level : return "Subordinate"
	if fear >= 25 and trust <= 25 and respect <= 25 : return "Bully"
	if other_fear >= 25 and other_trust <= 25 and other_respect <= 25 : return "Victim"
	if respect >= 70 and other_member.level > character_level + 1: return "Mentor"
	if respect >= 70 and other_member.level < character_level - 1: return "Protégé"
	if respect <= 25 and trust <= 25 : return "Contempt"
	if friend >= 70 and attract >= 35 : return "Lovers"
	if friend >= 75: return "Friends"
	if rival >= 20: return "Rivals"
	if trust <= 20: return "Distrusted"
	return "Acquaintances"	

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
	var new_character = PartyMember.new(
		character_name, character_class, character_portrait, character_level, character_sex,
		[], 
		max_health, base_damage,
		non_combat_stats.duplicate(true),
		personality_traits.duplicate(true)
	)
	new_character.character_unique_id = character_unique_id
	new_character.skill_list = skill_list.duplicate(true)
	new_character.character_experience = character_experience
	new_character.skill_points = skill_points
	new_character.spent_skill_points = spent_skill_points
	new_character.unspent_non_combat_stat_points = unspent_non_combat_stat_points
	return new_character
