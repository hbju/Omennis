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
