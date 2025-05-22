extends Node

var player_coords: Vector2
var party: Array[PartyMember]
var curr_candidate: PartyMember
const PARTY_MAX_NUMBER = 4

enum QUEST_STATE {Accepted, Accomplished, Turned}
var quest_log: Dictionary

var _condition_evaluators = {
	"party_full": func(): return party.size() == PARTY_MAX_NUMBER,
	"has_unspent_non_combat_points": func():
		for member in party:
			if member.unspent_non_combat_stat_points > 0: return true
		return false,
	"has_unspent_skill_points": func():
		for member in party:
			if member.skill_points > 0: return true
		return false,
}

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

func evaluate_condition_atom(atom: String, context_characters: Array[PartyMember] = []) -> bool:
	atom = atom.strip_edges()

	if _condition_evaluators.has(atom):
		return _condition_evaluators[atom].call()

	# Quest checks : accomplished or turned means accepted, turned means accomplished as well
	for state_name in ["accepted", "accomplished", "turned"]:
		var quest_id_str = quest_check(atom, "_" + state_name)
		if not quest_id_str.is_empty():
			var quest_id = int(quest_id_str)
			var expected_state = QUEST_STATE.get(state_name.capitalize()) 
			return quest_log.has(quest_id) and quest_log[quest_id] >= expected_state
	
	var gold_amount_str = gold_check(atom) # gold_X
	if not gold_amount_str.is_empty():
		return party_money >= int(gold_amount_str)

	# --- Stat, Trait, and Relationship Checks ---
	# Example patterns:
	# "stat_Perception_party_highest_gte_5"
	# "stat_Influence_char0_lte_3" (if context_characters[0] exists)
	# "trait_Valor_any_gte_2"
	# "rel_Friendship_char0_char1_gte_50"

	var parts = atom.split("_")
	if parts.size() < 4: 
		printerr("Malformed condition atom: ", atom)
		return false

	var type = parts[0] # "stat", "trait", "rel"
	var subject_field = parts[1] # e.g., "Perception", "Valor", "Friendship"
	
	var target_specifier = ""
	var operator_str = ""
	var value_str = ""

	# Heuristic to find operator and value, accommodating multi-part subjects
	# e.g. "stat_NonCombatLogistics_party_avg_gte_5"
	# We need to robustly find the operator (gte, lte, eq)
	var op_idx = -1
	for i in range(parts.size()-1, 1, -1): # Search backwards for operator
		if parts[i] in ["gte", "lte", "eq"]:
			op_idx = i
			break
	
	if op_idx == -1:
		printerr("Operator (gte, lte, eq) not found in condition: ", atom)
		return false

	operator_str = parts[op_idx]
	value_str = parts[op_idx + 1]
	target_specifier = "_".join(parts.slice(2, op_idx)) # Everything between field and operator

	var value = int(value_str)

	# --- Resolve Target Characters ---
	var characters_to_check: Array[PartyMember] = []
	if target_specifier.begins_with("char"): # char0, char1
		var char_idx = int(target_specifier.replace("char", ""))
		if char_idx < context_characters.size():
			characters_to_check.append(context_characters[char_idx])
		else:
			printerr("Invalid character index in condition: ", atom, " context size: ", context_characters.size())
			return false
	elif target_specifier == "any" or target_specifier == "party_highest" or target_specifier == "party_lowest" or target_specifier == "party_average":
		characters_to_check = party 
	else: # Default to checking current character if context available and no specifier
		if not context_characters.is_empty():
			characters_to_check.append(context_characters[0]) 
		else: # Or all party members if no specific context
			characters_to_check = party
	
	if characters_to_check.is_empty(): return false


	# --- Perform Evaluation ---
	match type:
		"stat":
			if target_specifier == "party_highest":
				var max_val = -INF
				for member in characters_to_check:
					if member.non_combat_stats.has(subject_field):
						max_val = max(max_val, member.non_combat_stats[subject_field])
				return _compare(max_val, operator_str, value)
			elif target_specifier == "party_lowest":
				var min_val = INF
				for member in characters_to_check:
					if member.non_combat_stats.has(subject_field):
						min_val = min(min_val, member.non_combat_stats[subject_field])
				return _compare(min_val, operator_str, value)
			elif target_specifier == "party_average":
				var total = 0
				var count = 0
				for member in characters_to_check:
					if member.non_combat_stats.has(subject_field):
						total += member.non_combat_stats[subject_field]
						count += 1
				if count == 0: return false 
				var average = total / count
				return _compare(average, operator_str, value)
			else: # "any" or specific character(s)
				for member in characters_to_check:
					if member.non_combat_stats.has(subject_field):
						if _compare(member.non_combat_stats[subject_field], operator_str, value):
							return true # "any" logic
				return false

		"trait":
			# Similar logic to stats, using member.personality_traits
			if target_specifier == "party_highest": # Max absolute value or just highest positive?
				var max_val = -INF 
				for member in characters_to_check:
					if member.personality_traits.has(subject_field):
						max_val = max(max_val, member.personality_traits[subject_field])
				return _compare(max_val, operator_str, value)
			elif target_specifier == "party_lowest":
				var min_val = INF
				for member in characters_to_check:
					if member.personality_traits.has(subject_field):
						min_val = min(min_val, member.personality_traits[subject_field])
				return _compare(min_val, operator_str, value)
			elif target_specifier == "party_average":
				var total = 0
				var count = 0
				for member in characters_to_check:
					if member.personality_traits.has(subject_field):
						total += member.personality_traits[subject_field]
						count += 1
				if count == 0: return false 
				var average = total / count
				return _compare(average, operator_str, value)
			else:
				for member in characters_to_check:
					if member.personality_traits.has(subject_field):
						if _compare(member.personality_traits[subject_field], operator_str, value):
							return true
				return false

		"rel": # e.g., "rel_Friendship_char0_char1_gte_50"
			if target_specifier == "party_highest":
				var max_val = -INF
				for member1 in characters_to_check:
					for member2 in characters_to_check:
						if member1 == member2: continue # Skip self-comparison
						var rel_score = member1.get_relationship_track_score(member2.character_unique_id, PartyMember.RELATIONSHIP_TRACK.get(subject_field.to_upper(), -1))
						max_val = max(max_val, rel_score)
				return _compare(max_val, operator_str, value)
			elif target_specifier == "party_lowest":
				var min_val = INF
				for member1 in characters_to_check:
					for member2 in characters_to_check:
						if member1 == member2: continue # Skip self-comparison
						var rel_score = member1.get_relationship_track_score(member2.character_unique_id, PartyMember.RELATIONSHIP_TRACK.get(subject_field.to_upper(), -1))
						min_val = min(min_val, rel_score)
				return _compare(min_val, operator_str, value)
			elif target_specifier == "party_average":
				var total = 0
				var count = 0
				for member1 in characters_to_check:
					for member2 in characters_to_check:
						if member1 == member2: continue # Skip self-comparison
						var rel_score = member1.get_relationship_track_score(member2.character_unique_id, PartyMember.RELATIONSHIP_TRACK.get(subject_field.to_upper(), -1))
						total += rel_score
						count += 1
				if count == 0: return false 
				var average = total / count
				return _compare(average, operator_str, value)
			else :
				if parts.size() < 5 : printerr("Malformed relationship condition: ", atom); return false
				var char_a_spec = parts[2]
				var char_b_spec = parts[3]
				operator_str = parts[4]
				value_str = parts[5]
				value = int(value_str)

				var char_a: PartyMember = null
				var char_b: PartyMember = null

				if char_a_spec.begins_with("char"):
					var char_a_idx = int(char_a_spec.replace("char",""))
					if char_a_idx < context_characters.size(): char_a = context_characters[char_a_idx]
				if char_b_spec.begins_with("char"):
					var char_b_idx = int(char_b_spec.replace("char",""))
					if char_b_idx < context_characters.size(): char_b = context_characters[char_b_idx]
				
				if not char_a or not char_b: 
					printerr("Could not find characters for relationship check: ", atom); return false
				
				var track_enum = PartyMember.RELATIONSHIP_TRACK.get(subject_field.to_upper(), -1)
				if track_enum == -1: printerr("Invalid relationship track: ", subject_field); return false
				
				var rel_score = char_a.get_relationship_track_score(char_b.character_unique_id, track_enum)
				return _compare(rel_score, operator_str, value)
			
	printerr("Unhandled condition atom type: ", atom)
	return false

func get_character_by_cond(condition: String) -> Array[PartyMember]:
	# Assuming condition is a string like "stat_Perception_party_highest_gte_50"
	var parts = condition.split("_")

	if parts.size() < 4: 
		printerr("Malformed condition: ", condition)
		return []

	var type = parts[0] # "stat", "trait", "rel"
	var subject_field = parts[1] # e.g., "Perception", "Valor", "Friendship"
	
	var target_specifier = ""
	var operator_str = ""
	var value_str = ""

	var op_idx = -1
	for i in range(parts.size()-1, 1, -1): # Search backwards for operator
		if parts[i] in ["gte", "lte", "eq"]:
			op_idx = i
			break
	
	if op_idx == -1:
		printerr("Operator (gte, lte, eq) not found in condition: ", condition)
		return []

	operator_str = parts[op_idx]
	value_str = parts[op_idx + 1]
	target_specifier = "_".join(parts.slice(2, op_idx)) # Everything between field and operator

	var value = int(value_str)

	# --- Resolve Target Characters ---
	var characters_to_check: Array[PartyMember] = []
	var context_characters: Array[PartyMember] = GameState.party 

	if target_specifier.begins_with("char"): # char0, char1
		var char_idx = int(target_specifier.replace("char", ""))
		if char_idx < context_characters.size():
			characters_to_check.append(context_characters[char_idx])
		else:
			printerr("Invalid character index in condition: ", condition, " context size: ", context_characters.size())
			return []
	elif target_specifier == "any" or target_specifier == "party_highest" or target_specifier == "party_lowest" or target_specifier == "party_average":
		characters_to_check = context_characters 
	else: # Default to checking current character if context available and no specifier
		if not context_characters.is_empty():
			characters_to_check.append(context_characters[0]) 
		else: # Or all party members if no specific context
			characters_to_check = context_characters
	
	if characters_to_check.is_empty(): return []


	# --- Perform Evaluation ---
	match type:
		"stat":
			if target_specifier == "party_highest":
				var max_val = -INF
				var max_member: PartyMember = null
				for member in characters_to_check:
					if member.non_combat_stats.has(subject_field):
						max_val = max(max_val, member.non_combat_stats[subject_field])
						if max_val == member.non_combat_stats[subject_field]:
							max_member = member
				if (_compare(max_val, operator_str, value)) :
					return [max_member]

			elif target_specifier == "party_lowest":
				var min_val = INF
				var min_member: PartyMember = null
				for member in characters_to_check:
					if member.non_combat_stats.has(subject_field):
						min_val = min(min_val, member.non_combat_stats[subject_field])
						if min_val == member.non_combat_stats[subject_field]:
							min_member = member
				if (_compare(min_val, operator_str, value)) :
					return [min_member]

			else: # "any" or specific character(s)
				var characters = []
				for member in characters_to_check:
					if member.non_combat_stats.has(subject_field):
						if _compare(member.non_combat_stats[subject_field], operator_str, value):
							characters.append(member)
				return characters

		"trait":
			# Similar logic to stats, using member.personality_traits
			if target_specifier == "party_highest": # Max absolute value or just highest positive?
				var max_val = -INF
				var max_member: PartyMember = null
				for member in characters_to_check:
					if member.personality_traits.has(subject_field):
						max_val = max(max_val, member.personality_traits[subject_field])
						if max_val == member.personality_traits[subject_field]:
							max_member = member
				if (_compare(max_val, operator_str, value)) :
					return [max_member]

			elif target_specifier == "party_lowest":
				var min_val = INF
				var min_member: PartyMember = null
				for member in characters_to_check:
					if member.personality_traits.has(subject_field):
						min_val = min(min_val, member.personality_traits[subject_field])
						if min_val == member.personality_traits[subject_field]:
							min_member = member
				if (_compare(min_val, operator_str, value)) :
					return [min_member]

			else: # "any" or specific character(s)
				var characters = []
				for member in characters_to_check:
					if member.personality_traits.has(subject_field):
						if _compare(member.personality_traits[subject_field], operator_str, value):
							characters.append(member)
				return characters

		"rel": # e.g., "rel_Friendship_char0_char1_gte_50"
			if target_specifier == "party_highest":
				var max_val = -INF
				var target_member1: PartyMember = null
				var target_member2: PartyMember = null
				for member1 in characters_to_check:
					for member2 in characters_to_check:
						if member1 == member2: continue # Skip self-comparison
						var rel_score = member1.get_relationship_track_score(member2.character_unique_id, PartyMember.RELATIONSHIP_TRACK.get(subject_field.to_upper(), -1))
						max_val = max(max_val, rel_score)
						if max_val == rel_score:
							target_member1 = member1
							target_member2 = member2
				if (_compare(max_val, operator_str, value)) :
					return [target_member1, target_member2]
			
			elif target_specifier == "party_lowest":
				var min_val = INF
				var target_member1: PartyMember = null
				var target_member2: PartyMember = null
				for member1 in characters_to_check:
					for member2 in characters_to_check:
						if member1 == member2: continue # Skip self-comparison
						var rel_score = member1.get_relationship_track_score(member2.character_unique_id, PartyMember.RELATIONSHIP_TRACK.get(subject_field.to_upper(), -1))
						min_val = min(min_val, rel_score)
						if min_val == rel_score:
							target_member1 = member1
							target_member2 = member2
				if (_compare(min_val, operator_str, value)) :
					return [target_member1, target_member2]

			else :
				if parts.size() < 5 : printerr("Malformed relationship condition: ", condition); return []
				var char_a_spec = parts[2]
				var char_b_spec = parts[3]
				operator_str = parts[4]
				value = int(parts[5])

				var char_a: PartyMember = null
				var char_b: PartyMember = null

				if char_a_spec.begins_with("char"):
					var char_a_idx = int(char_a_spec.replace("char",""))
					if char_a_idx < context_characters.size(): char_a = context_characters[char_a_idx]
				if char_b_spec.begins_with("char"):
					var char_b_idx = int(char_b_spec.replace("char",""))
					if char_b_idx < context_characters.size(): char_b = context_characters[char_b_idx]
				
				if not char_a or not char_b: 
					printerr("Could not find characters for relationship check: ", condition); return []
				
				var track_enum = PartyMember.RELATIONSHIP_TRACK.get(subject_field.to_upper(), -1)
				if track_enum == -1: printerr("Invalid relationship track: ", subject_field); return []
				
				var rel_score = char_a.get_relationship_track_score(char_b.character_unique_id, track_enum)
				if (_compare(rel_score, operator_str, value)) :
					return [char_a, char_b]
				else:
					return [] # No characters met the condition
	printerr("Unhandled condition atom type: ", condition)
	return []


func _compare(val1, operator_str: String, val2) -> bool:
	match operator_str:
		"gte": return val1 >= val2
		"lte": return val1 <= val2
		"eq": return val1 == val2
	return false

const OPERATORS = {
	"OR": {"precedence": 1, "associativity": "Left"},
	"AND": {"precedence": 2, "associativity": "Left"},
	"NOT": {"precedence": 3, "associativity": "Right"} # Unary operator
}

func _tokenize_expression(expression: String) -> Array:
	var tokens: Array = []

	# Add spaces around parentheses and operators to make splitting easier
	var spaced_expression = expression
	spaced_expression = spaced_expression.replace("(", " ( ")
	spaced_expression = spaced_expression.replace(")", " ) ")

	# Case-insensitive replacement for operators
	var re_and = RegEx.new()
	re_and.compile("\\bAND\\b")
	spaced_expression = re_and.sub(spaced_expression, " AND ", true)
	
	var re_or = RegEx.new()
	re_or.compile("\\bOR\\b")
	spaced_expression = re_or.sub(spaced_expression, " OR ", true)

	var re_not = RegEx.new()
	re_not.compile("\\bNOT\\b")
	spaced_expression = re_not.sub(spaced_expression, " NOT ", true)
	
	var raw_tokens = spaced_expression.split(" ", false)

	for token_str in raw_tokens:
		if token_str.is_empty():
			continue
		tokens.append(token_str.strip_edges().to_upper() if token_str.to_upper() in ["AND", "OR", "NOT", "(", ")"] else token_str.strip_edges())
	
	print("Tokenized: ", tokens)
	return tokens

func _infix_to_rpn(tokens: Array) -> Array:
	var output_queue: Array = []
	var operator_stack: Array = []

	for token in tokens:
		if token == "(":
			operator_stack.push_back(token)
		elif token == ")":
			while not operator_stack.is_empty() and operator_stack.back() != "(":
				output_queue.push_back(operator_stack.pop_back())
			if operator_stack.is_empty(): # Mismatched parentheses
				printerr("Error: Mismatched parentheses in expression (missing '(').")
				return []
			operator_stack.pop_back() # Pop the "("
		elif token in OPERATORS: # Is an operator
			var op1 = token
			while not operator_stack.is_empty() and operator_stack.back() != "(":
				var op2_token = operator_stack.back()
				if not op2_token in OPERATORS: break # Not an operator, stop

				var op1_data = OPERATORS[op1]
				var op2_data = OPERATORS[op2_token]

				if (op1_data.associativity == "Left" and op1_data.precedence <= op2_data.precedence) or \
				   (op1_data.associativity == "Right" and op1_data.precedence < op2_data.precedence):
					output_queue.push_back(operator_stack.pop_back())
				else:
					break
			operator_stack.push_back(op1)
		else: # Is an operand (our condition atom)
			output_queue.push_back(token)

	while not operator_stack.is_empty():
		var op = operator_stack.pop_back()
		if op == "(" : # Mismatched parentheses
			printerr("Error: Mismatched parentheses in expression (extra '(').")
			return [] # Error
		output_queue.push_back(op)
	
	print("RPN: ", output_queue)
	return output_queue

func _evaluate_rpn(rpn_tokens: Array, context_characters: Array[PartyMember] = []) -> bool:
	var operand_stack: Array = []

	for token in rpn_tokens:
		if token in OPERATORS: # Is an operator
			if token == "NOT":
				if operand_stack.is_empty():
					printerr("RPN Error: Insufficient operands for NOT.")
					return false 
				var operand = operand_stack.pop_back()
				if not typeof(operand) == TYPE_BOOL: printerr("RPN Error: Operand for NOT not a bool."); return false
				operand_stack.push_back(not operand)
			else: # AND, OR (binary operators)
				if operand_stack.size() < 2:
					printerr("RPN Error: Insufficient operands for ", token)
					return false 
				var op2 = operand_stack.pop_back()
				var op1 = operand_stack.pop_back()
				if not typeof(op1) == TYPE_BOOL or not typeof(op2) == TYPE_BOOL:
					printerr("RPN Error: Operands for ", token, " not booleans.")
					return false

				if token == "AND":
					operand_stack.push_back(op1 and op2)
				elif token == "OR":
					operand_stack.push_back(op1 or op2)
		else: # Is an operand 
			var result = evaluate_condition_atom(token, context_characters) 
			operand_stack.push_back(result)

	if operand_stack.size() == 1 and typeof(operand_stack[0]) == TYPE_BOOL:
		return operand_stack[0]
	else:
		printerr("RPN Evaluation Error: Stack did not resolve to a single boolean. Stack: ", operand_stack)
		return false # Error

func check_complex_condition(expression: String, context_characters: Array[PartyMember] = []) -> bool:
	if expression.is_empty():
		return true

	var tokens = _tokenize_expression(expression)
	if tokens.is_empty() and not expression.is_empty(): # Tokenization failed for non-empty string
		printerr("Condition tokenization failed for: '", expression, "'")
		return false
	
	if tokens.is_empty() and expression.is_empty(): # Empty expression might mean always true
		return true

	var rpn_expression = _infix_to_rpn(tokens)
	if rpn_expression.is_empty() and not tokens.is_empty(): # RPN conversion failed
		printerr("RPN conversion failed for tokens: ", tokens)
		return false

	if rpn_expression.is_empty() and tokens.is_empty() and expression.is_empty():
		return true
	
	return _evaluate_rpn(rpn_expression, context_characters)

func evaluate_expression(condition_id: String) -> bool:
	return check_complex_condition(condition_id)


func step_taken() : 
	steps_until_event -= 1
	if steps_until_event == 0 : 
		steps_until_event = randi_range(12, 20)
		random_event.emit()
