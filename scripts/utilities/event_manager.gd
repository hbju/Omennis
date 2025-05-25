class_name EventManager

var event_ui: EventUI
var fight_ui: FightUI
var curr_fight: String
var fight_victory_event_id: String = ""
var fight_defeat_event_id: String = ""

var curr_place = ""

func _init(_event_ui: EventUI, _fight_ui: FightUI) :
	self.event_ui = _event_ui
	self.fight_ui = _fight_ui
	event_ui.resolve_event.connect(event_manager)

func event_manager(event_id_or_choice_id: String): 
	
	var current_event_data = event_ui.current_event_json_data

	if not current_event_data or not current_event_data.has("possibilities"):
		if event_id_or_choice_id == "leave": leave_event(); return
		 # If it's an ID that's not 'leave' and no current_event_data, it's a direct event jump
		_show_event_by_id(event_id_or_choice_id)
		return

	var chosen_possibility = null
	for p in current_event_data.possibilities:
		if p.id == event_id_or_choice_id:
			chosen_possibility = p
			break
	
	if not chosen_possibility:
		printerr("EventManager: Could not find choice with ID: ", event_id_or_choice_id, " in current event.")
		leave_event() # Fallback
		return

	if chosen_possibility.has("outcomes"):
		process_outcomes(chosen_possibility.outcomes)
	else: 
		if event_id_or_choice_id != "leave":
			_show_event_by_id(event_id_or_choice_id)
		else:
			leave_event()


func process_outcomes(outcomes: Array):
	var next_event_id_from_outcomes = ""
	var fight_to_start: Array[EnemyGroup] = []

	for outcome in outcomes:
		var outcome_type = outcome.get("type", "")

		if outcome.has("condition") and not GameState.check_complex_condition(outcome.condition, GameState.party):
			continue # Skip this outcome if its condition isn't met

		match outcome_type:
			"gold": # E.g., {"type": "gold", "change": 100}
				GameState.change_gold(outcome.change)
			"xp": # E.g., {"type": "xp", "amount": 50}
				GameState.receive_experience(outcome.amount)
			"quest_update": # E.g., {"type": "quest_update", "quest_id": 1, "action": "accept/accomplish/turn"}
				var quest_id = outcome.quest_id
				match outcome.action:
					"accept": GameState.accept_quest(quest_id)
					"accomplish": GameState.accomplish_quest(quest_id)
					"turn": GameState.turn_quest(quest_id)
			"flag_set": # E.g., {"type": "flag_set", "flag": "some_flag", "value": true}
				GameState.set_flag(outcome.flag, outcome.value)
			"trait_change": # {"type": "trait_change", "char_cond":"stat_Perception_party_highest_gte_50", "trait": "Valor", "change": 1}
				var chars_to_affect = GameState.party if not outcome.has("char_cond") else GameState.get_character_by_cond(outcome.char_cond)
				for char_to_affect in chars_to_affect:
					char_to_affect.adjust_personality_trait(outcome.trait, outcome.change)
			"relationship_change":
				# {"type": "relationship", "char_cond":"rel_Friendship_praty_highest_lte_30" , "track": "FRIENDSHIP", "change": 10}
				var chars = GameState.get_character_by_cond(outcome.char_cond)
				if chars.size() < 2:
					printerr("Not enough characters for relationship change: ", outcome.char_cond)
					continue
				var char_a = chars[0]
				var char_b = chars[1]
				var track_enum = PartyMember.RELATIONSHIP_TRACK.get(outcome.track.to_upper(), -1)
				if track_enum != -1:
					char_a.adjust_relationship_track_score(char_b.character_unique_id, track_enum, outcome.change)
					if outcome.get("symmetrical", true): # Assume symmetrical unless specified
						char_b.adjust_relationship_track_score(char_a.character_unique_id, track_enum, outcome.change)
			"start_fight": # {"type": "start_fight", "enemies": [{"archetype":"Mountain Drake", "enemy_count": 3, "enemy_level": 2, "enemy_name": "Drakes", "enemy_portrait":2}], "event_id_victory": "fight_drake_ambush_victory", "event_id_defeat": "fight_drake_ambush_defeat"}

				for enemy_data in outcome.enemies:
					var enemy_archetype = enemy_data.get("archetype", "Mountain Drake")
					var enemy_count = enemy_data.get("enemy_count", 1)
					var enemy_level = enemy_data.get("enemy_level", 1)
					var enemy_name = enemy_data.get("enemy_name", "")
					var enemy_portrait = enemy_data.get("enemy_portrait", -1)
					
					# Create the EnemyGroup from the data
					var new_enemy_group = EnemyGroup.from_enemy_data(enemy_archetype, enemy_level, enemy_count, enemy_name, enemy_portrait)
					fight_to_start.append(new_enemy_group) # Add the main enemy character to the list

				fight_victory_event_id = outcome.event_id_victory
				fight_defeat_event_id = outcome.event_id_defeat
			"next_event":
				next_event_id_from_outcomes = outcome.event_id
			"recruit_pending_candidate":
				GameState.recruit_candidate()
			"display_new_candidate": # Used for recruiting events
				display_new_member() # Your existing function
			_ :
				printerr("EventManager: Unknown outcome type: ", outcome_type)
				continue # Skip unknown types

	# After processing all conditional outcomes:
	if fight_to_start:
		enter_fight(fight_to_start)
	elif not next_event_id_from_outcomes.is_empty():
		if next_event_id_from_outcomes == "leave":
			leave_event()
		else:
			_show_event_by_id(next_event_id_from_outcomes)
	else:
		 # If no "next_event" specified, and not a fight, assume error
		printerr("EventManager: No next event or fight to start. Leaving event.")


func _compare(val1, operator_str: String, val2) -> bool:
	match operator_str:
		"gte": return val1 >= val2
		"lte": return val1 <= val2
		"eq": return val1 == val2
	return false

func _show_event_by_id(event_id: String):
	# Assuming EventUI's show_event now takes context_characters
	event_ui.show_event(curr_place, event_id, GameState.party)


func random_event_manager(_event_content: Dictionary) : 
	var _party = GameState.party
	#TODO change party to whatever
	# event_ui.show_event("conversation", "conversation", party, true)
	# event_ui.visible = true
	# GameState.in_event = true


func enter_event(place_id: String) :
	self.curr_place = place_id

	event_ui.show_event(place_id, place_id)
	event_ui.visible = true
	GameState.in_event = true
	
func display_new_member() :
	var candidate: PartyMember = PartyMember.new_rand()
	GameState.new_candidate(candidate)
	
	
func leave_event() : 
	event_ui.visible = false
	GameState.in_event = false
	
func enter_fight(enemy_group: Array[EnemyGroup]) :
	fight_ui.visible = true
	fight_ui.update_ui(GameState.party, enemy_group)
	event_ui.visible = false
	
func exit_fight(victory: bool) :
	fight_ui.visible = false
	var next_event = fight_victory_event_id if victory else fight_defeat_event_id
	event_ui.visible = true
	event_ui.current_event_json_data = {}
	event_manager(next_event)