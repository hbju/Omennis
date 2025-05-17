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
