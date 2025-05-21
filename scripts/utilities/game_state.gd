extends Node

var player_coords: Vector2
var party: Array[PartyMember]
var curr_candidate: PartyMember
const PARTY_MAX_NUMBER = 4

enum QUEST_STATE {Accepted, Accomplished, Turned}
var quest_log: Dictionary

var party_money : int
signal money_changed

var in_ui: bool = false
var in_event: bool = false

var steps_until_event: int = randi_range(12, 20)
signal random_event

func _ready():
	party.append(PartyMember.new_rand())
	
	
## PARTY LOGIC 
func recruit_candidate() :
	party.append(curr_candidate)
	curr_candidate = null

	var new_member = party.back()
	for existing_member in party:
		if existing_member.character_unique_id == new_member.character_unique_id:
			continue # Don't create relationship with self
		_seed_initial_relationship(new_member, existing_member)
		_seed_initial_relationship(existing_member, new_member)
	

func _seed_initial_relationship(char_a: PartyMember, char_b: PartyMember):
	if char_a == char_b: return # Sanity check

	var a_traits = char_a.personality_traits
	var b_traits = char_b.personality_traits

	# --- Valor Scale Interaction ---
	var a_valor = a_traits.get("Valor", 0)
	var b_valor = b_traits.get("Valor", 0)

	# Friendship: Mutual bravery or mutual timidity can create a bond. Large differences can create friction or respect/fear.
	if (a_valor > 0 and b_valor > 0):
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, (a_valor + b_valor) * 1)
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, (a_valor + b_valor) * 2)
	elif (a_valor < 0 and b_valor < 0): # Both somewhat timid
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, abs(a_valor + b_valor) * 2)
	elif (a_valor > 2 and b_valor < -2): # Brave A views Timid B
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, b_valor * 2) # Negative respect, -1 to -2.5
	elif (a_valor < -2 and b_valor > 2): # Timid A views Brave B
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, b_valor * 1) # Positive respect, 1.2 to 3
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FEAR, b_valor * 2)    # Scale: 0.8 to 2

	# --- Approach Scale Interaction ---
	var a_temper = a_traits.get("Temper", 0)
	var b_temper = b_traits.get("Temper", 0)

	# Friendship/Rivalry: Similar approaches bond, differing approaches can lead to friction or rivalry.
	if (a_temper * b_temper > 0): # Both cautious OR both impulsive (same sign)
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, abs(a_temper + b_temper) * 1) # Scale: 0.4 to 4
	else: # One cautious, one impulsive (opposite signs or one is 0)
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, abs(a_temper - b_temper) * 1) # Minor dislike, 0 to -2
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RIVALRY, abs(a_temper - b_temper) * 1)   # Scale: 0 to 3

	# Respect: Meticulous people might respect other meticulous people. Impulsive might find meticulous slow, or vice versa.
	if (a_temper < -2 and b_temper < -2): # Both very meticulous
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, abs(a_temper + b_temper) * 1) # Scale: 0.8 to 2
	elif (a_temper > 2 and b_temper < -2): # Impulsive A views Meticulous B
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, b_temper * 1) # Can be negative, -0.6 to -1.5 (sees them as slow)

	# --- Ethics Scale Interaction ---
	var a_ethics = a_traits.get("Ethics", 0)
	var b_ethics = b_traits.get("Ethics", 0)

	# Friendship/Distrust: Strong indicator. Similar ethics bond, differing ethics create distrust.
	if (a_ethics * b_ethics >= 0): # Same ethical leaning (both positive, both negative, or one/both zero)
		# If both are strongly ethical (positive) or both strongly unethical (negative), can form a bond of sorts
		if abs(a_ethics) > 2 and abs(b_ethics) > 2:
			char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, (abs(a_ethics) + abs(b_ethics)) * 2) # Scale: 2 to 5
			char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.TRUST, (abs(a_ethics) + abs(b_ethics)) * 1)
		elif abs(a_ethics) > 0 and abs(b_ethics) > 0: # Both non-zero and same sign
			char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, (abs(a_ethics) + abs(b_ethics)) * 1)
	else: # Opposite ethical leanings
		var ethical_difference = abs(a_ethics - b_ethics)
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, -ethical_difference * 2) # Scale: -0.6 to -6 (strong dislike)
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.TRUST, ethical_difference * -1)    # Scale: 0.8 to 8 (strong distrust)
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RIVALRY, ethical_difference * 2)

	# Respect: Altruistic people respect other altruists. Self-serving might respect ruthless efficiency.
	if (a_ethics > 2 and b_ethics > 2): # Both Altruistic
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, (a_ethics + b_ethics) * 1) # Scale: 1.6 to 4
	elif (a_ethics < -2 and b_ethics < -2): # Both Self-Serving/Ruthless
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, abs(a_ethics + b_ethics) * 0.5) # Grudging respect for fellow scoundrel
	elif (a_ethics > 2 and b_ethics < -2): # Altruistic A views Ruthless B
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, (-a_ethics + b_ethics) * 2) # Strong negative respect (disdain), -1.6 to -4

	# --- Worldview Scale Interaction (Assuming Optimistic for +5) ---
	var a_worldview = a_traits.get("Worldview", 0)
	var b_worldview = b_traits.get("Worldview", 0)

	# Friendship: Shared optimism or shared cynicism can bond. Opposites can clash.
	if (a_worldview > 0 and b_worldview > 0): # Both Optimistic/Inquisitive
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, (a_worldview + b_worldview) * 2) # Scale: 0.5 to 5
	elif (a_worldview < 0 and b_worldview < 0): # Both Cynical
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, abs(a_worldview + b_worldview) * 1) # Misery loves company, 0.4 to 4
	elif (a_worldview * b_worldview < 0): # One optimistic, one cynical
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, -abs(a_worldview - b_worldview) * 1) # Scale: -0.3 to -3
		char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RIVALRY, abs(a_worldview - b_worldview) * 2) # Major ideological friction


	# Attraction/Fear are less directly seeded by these general personality traits initially,
	# unless specific combinations are designed by Jonathan (e.g., a very Timid char might be Attracted to a very Brave one,
	# or a Ruthless char might instill Fear in an Altruistic one if there's a power dynamic).
	# These are better influenced by specific event interactions.

	# --- Class-Based Modifiers (Subtle) ---
	# (Jonathan can expand this)
	if char_a.character_class == Character.CLASSES.Warrior:
		if char_b.character_class == Character.CLASSES.Warrior:
			char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, 5)
		elif char_b.character_class == Character.CLASSES.Mage:
			char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.TRUST, -3) # Slight initial warrior distrust of mages
	
	elif char_a.character_class == Character.CLASSES.Mage:
		if char_b.character_class == Character.CLASSES.Mage:
			char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, 5)
		elif char_b.character_class == Character.CLASSES.Warrior and b_valor > 2: # Mage respects a brave warrior
			char_a.adjust_relationship_track_score(char_b.character_unique_id, PartyMember.RELATIONSHIP_TRACK.RESPECT, 3) # Slight initial mage respect of brave warriors



func new_candidate(candidate: PartyMember): 
	curr_candidate = candidate

func receive_experience(experience: int) -> Array[int] : 
	var received_xp: Array[int] = []
	for character in party : 
		var xp: int = round(experience * randf_range(0.9, 1.1))
		character.receive_experience(xp)
		received_xp.append(xp)
	return received_xp
		
func fire_member(index: int) : 
	party.remove_at(index)	
	
## QUEST LOGIC
	
func accept_quest(quest_id: int):
	quest_log[quest_id] = QUEST_STATE.Accepted

func accomplish_quest(quest_id: int):
	quest_log[quest_id] = QUEST_STATE.Accomplished
	
func turn_quest(quest_id: int) :
	quest_log[quest_id] = QUEST_STATE.Turned
	
## MONEY LOGIC	
	
func change_gold(amount: int) : 
	party_money += amount
	money_changed.emit()
	
## CONDITION LOGIC

func conditions(expression: String) -> bool:
	expression.strip_edges()
	if expression.begins_with("not(") and expression.ends_with(")"):
		var inner_expression = expression.substr(4, expression.length() - 5)
		return not evaluate_expression(inner_expression)
	
	# If the expression is a single condition ID
	return evaluate_expression(expression)

	
func quest_check(condition_id: String, quest_condition: String) -> String :
	var regex = RegEx.new()
	regex.compile(r"quest_(.+)" + quest_condition)
	var regex_match = regex.search(condition_id)
	if regex_match : 
		return regex_match.get_string(1)
	return ""
		
func gold_check(condition_id: String) -> String : 
	var regex = RegEx.new()
	regex.compile(r"gold_(.+)")
	var regex_match = regex.search(condition_id)
	if regex_match : 
		return regex_match.get_string(1)
	return ""

func stat_check(condition_id: String, comparison: String) -> Array: # Returns [stat_name, value] or empty
	var regex = RegEx.new()
	# Matches "stat_STATNAME_gte_VALUE" or "stat_STATNAME_lte_VALUE" or "stat_STATNAME_eq_VALUE"
	regex.compile(r"stat_([A-Za-z]+)_(gte|lte|eq)_(\d+)")
	var regex_match = regex.search(condition_id)
	if regex_match:
		return [regex_match.get_string(1), comparison, int(regex_match.get_string(3))]
	return []
		
func trait_check(condition_id: String, comparison: String) -> Array: # Returns [trait_name, value] or empty
	var regex = RegEx.new()
	# Matches "trait_TRAITNAME_gte_VALUE" or "trait_TRAITNAME_lte_VALUE" or "trait_TRAITNAME_eq_VALUE"
	regex.compile(r"trait_([A-Za-z]+)_(gte|lte|eq)_([+-]?\d+)")
	var regex_match = regex.search(condition_id)
	if regex_match:
		return [regex_match.get_string(1), comparison, int(regex_match.get_string(3))]
	return []

func evaluate_expression(condition_id: String) -> bool:
	var quest_accepted_id = quest_check(condition_id, "_accepted")
	if quest_accepted_id != "" :
		return quest_log.has(int(quest_accepted_id)) && quest_log[int(quest_accepted_id)] == QUEST_STATE.Accepted
		
	var quest_accomplished_id = quest_check(condition_id, "_accomplished")
	if quest_accomplished_id != "" :
		return quest_log.has(int(quest_accomplished_id)) && quest_log[int(quest_accomplished_id)] == QUEST_STATE.Accomplished
	
	var quest_turned_id = quest_check(condition_id, "_turned")
	if quest_turned_id != "" :
		return quest_log.has(int(quest_turned_id)) && quest_log[int(quest_turned_id)] == QUEST_STATE.Turned
		
	var gold_amount = gold_check(condition_id)
	if gold_amount != "" : 
		return party_money >= int(gold_amount)

	var stat_gte = stat_check(condition_id, "gte")
	if not stat_gte.is_empty():
		for member in party:
			if member.non_combat_stats.has(stat_gte[0]) and member.non_combat_stats[stat_gte[0]] >= stat_gte[2]:
				return true
		return false

	var stat_lte = stat_check(condition_id, "lte")
	if not stat_lte.is_empty():
		for member in party:
			if member.non_combat_stats.has(stat_lte[0]) and member.non_combat_stats[stat_lte[0]] <= stat_lte[2]:
				return true
		return false

	var stat_eq = stat_check(condition_id, "eq")
	if not stat_eq.is_empty():
		for member in party:
			if member.non_combat_stats.has(stat_eq[0]) and member.non_combat_stats[stat_eq[0]] == stat_eq[2]:
				return true
		return false

	var trait_gte = trait_check(condition_id, "gte")
	if not trait_gte.is_empty():
		for member in party: 
			if member.personality_traits.has(trait_gte[0]) and member.personality_traits[trait_gte[0]] >= trait_gte[2]:
				return true
		return false
	
	var trait_lte = trait_check(condition_id, "lte")
	if not trait_lte.is_empty():
		for member in party: 
			if member.personality_traits.has(trait_lte[0]) and member.personality_traits[trait_lte[0]] <= trait_lte[2]:
				return true
		return false

	var trait_eq = trait_check(condition_id, "eq")
	if not trait_eq.is_empty():
		for member in party: 
			if member.personality_traits.has(trait_eq[0]) and member.personality_traits[trait_eq[0]] == trait_eq[2]:
				return true
		return false
		
	match condition_id :
		"quest_accepted" :
			for quest in quest_log : 
				if quest_log[quest] == QUEST_STATE.Accepted : 
					return true
			return false
		"quest_accomplished" :
			for quest in quest_log : 
				if quest_log[quest] == QUEST_STATE.Accomplished : 
					return true
			return false
		"quest_turned" :
			for quest in quest_log : 
				if quest_log[quest] == QUEST_STATE.Turned : 
					return true
			return false
		"party_full" :
			return party.size() == PARTY_MAX_NUMBER

	push_error("unknown condition " + condition_id)
	return false


func step_taken() : 
	steps_until_event -= 1
	if steps_until_event == 0 : 
		steps_until_event = randi_range(12, 20)
		random_event.emit()
