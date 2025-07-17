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

var equipment_slots: Dictionary = {
	"armor": null,
	"weapon": null,
	"accessory": null
}
var weapon_skill: Skill = null # Skill granted by the equipped weapon, if any

const NB_FEMALE_PORTRAIT = 36
const NB_MALE_PORTRAIT = 21

enum SEX {Male, Female, Other}

func _init(char_name, _class, portrait, level, sex, 
		skills: Array[Skill] = [], 
		initial_health: int = 100, initial_damage: float = 10,
		initial_non_combat_stats: Dictionary = {},
		initial_trait_scores: Dictionary = {}):
	super(char_name, _class, portrait, level, initial_health, initial_damage)

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

	_recalculate_stats()

	
static func new_rand(char_class: Character.CLASSES = Character.CLASSES.None) -> PartyMember: 
	var sex = randi_range(0, 1)
	var names = load("res://text/characters/" + ("female_character_names.json" if sex == 1 else "male_character_names.json")).data.names
	var char_name = names[randi() % names.size()]
	var portrait = randi() % (NB_FEMALE_PORTRAIT if sex == 1 else NB_MALE_PORTRAIT)
	char_class = CLASSES.values()[randi_range(0, CLASSES.size() - 2)] if char_class == Character.CLASSES.None else char_class

	var new_char = PartyMember.new(char_name, char_class, portrait, 1, sex)
	
	return new_char
	
func receive_experience(experience: int) : 
	var threshold = next_level()
	character_experience += experience
	while character_experience > threshold : 
		character_level += 1
		skill_points += 1
		unspent_non_combat_stat_points += 2
		self._base_max_health += round(0.2 * self._base_max_health * randf_range(0.9, 1.1))
		self._base_damage += round(0.1 * self._base_damage * randf_range(0.9, 1.1))

		_recalculate_stats()

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

func equip_item(item_to_equip: BaseItem):
	if not item_to_equip:
		printerr("Attempted to equip a null item.")
		return
		
	var target_slot_key = ""
	if item_to_equip is WeaponItem:
		target_slot_key = "weapon"
	elif item_to_equip is EquipmentItem:
		match item_to_equip.equip_slot:
			EquipmentItem.EquipSlot.ARMOR:
				target_slot_key = "armor"
			EquipmentItem.EquipSlot.ACCESSORY:
				target_slot_key = "accessory"
	
	if target_slot_key.is_empty():
		printerr("Item has no valid slot: ", item_to_equip.item_name)
		return

	var previously_equipped_item = equipment_slots[target_slot_key]

	GameState.party_inventory.erase(item_to_equip)
	equipment_slots[target_slot_key] = item_to_equip
	
	if previously_equipped_item:
		GameState.party_inventory.append(previously_equipped_item)
	
	_recalculate_stats()
	print("%s equipped %s." % [self.character_name, item_to_equip.item_name])

func unequip_item(slot_key_to_unequip: String):
	if not equipment_slots.has(slot_key_to_unequip):
		printerr("Attempted to unequip from an invalid slot: ", slot_key_to_unequip)
		return

	var item_to_unequip = equipment_slots[slot_key_to_unequip]
	if not item_to_unequip:
		return

	GameState.party_inventory.append(item_to_unequip)
	equipment_slots[slot_key_to_unequip] = null

	_recalculate_stats()
	print("%s unequipped %s." % [self.character_name, item_to_unequip.item_name])

func _recalculate_stats():
	# The final stats in the parent Character class are reset to the PartyMember's base stats.
	self.max_health = self._base_max_health
	self.damage = self._base_damage
	self.crit_chance = 0.05 # Base 5%
	self.crit_damage_multiplier = 1.5 # Base 150%
	print("%s recalculating stats..." % self.character_name)
	print("Base stats: Max Health = %d, Damage = %.2f, Crit Chance = %.2f" % 
		[self._base_max_health, self._base_damage, self.crit_chance])

	# Reset item-specific variables
	self.weapon_skill = null
	self.init_shield = 0
	
	# In the future, we would clear all passives from gear here too.

	for slot_key in equipment_slots:
		var item = equipment_slots[slot_key]
		if not item:
			continue # Skip empty slot

		# Apply bonuses based on item type
		if item is WeaponItem:
			print("Applying bonuses from %s in slot %s" % [item.item_name, slot_key])
			self.damage += item.damage_bonus
			self.crit_chance += item.crit_chance_bonus
			if item.granted_skill:
				self.weapon_skill = item.granted_skill.duplicate(true)
		
		elif item is EquipmentItem:
			print("Applying bonuses from %s in slot %s, item stats : %s, %s" % [item.item_name, slot_key, item.health_bonus, item.armor_bonus])
			self.max_health += item.health_bonus
			self.init_shield += item.armor_bonus
			print("Stats after applying %s: Max Health = %d, Damage = %.2f" % 
				[item.item_name, self.max_health, self.damage])

	print("%s recalculated stats: Max Health = %d, Damage = %.2f, Crit Chance = %.2f" % 
		[self.character_name, self.max_health, self.damage, self.crit_chance])


func reset_skills():
	super()
	if weapon_skill:
		weapon_skill.cooldown = 0

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
		self._base_max_health, self._base_damage,
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
