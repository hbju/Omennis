class_name EventManager

var event_ui: EventUI
var fight_ui: FightUI
var curr_fight: String
var fight_victory_event_id: String = ""
var fight_defeat_event_id: String = ""

var curr_place = ""

func _init(_event_ui: EventUI, _fight_ui: FightUI):
	self.event_ui = _event_ui
	self.fight_ui = _fight_ui
	event_ui.resolve_event.connect(event_manager)

func event_manager(event_id_or_choice_id: String):
	if event_id_or_choice_id == "accept_radiant_quest":
		RadiantQuestManager.finalize_quest_acceptance()
		# Go back to the guild hall screen
		_show_event_by_id("evt_" + self.curr_place + "_guild")
		return

	if event_id_or_choice_id == "decline_radiant_quest":
		RadiantQuestManager.clear_pending_quest()
		# Go back to the guild hall screen
		_show_event_by_id("evt_" + self.curr_place + "_guild")
		return

	if event_id_or_choice_id == "start_radiant_fight":
				var radiant_quest: Dictionary = RadiantQuestManager.get_active_quest()
				if not radiant_quest:
					printerr("No active radiant quest found.")
					return
				var template: RadiantQuestTemplate = radiant_quest.template as RadiantQuestTemplate
				var fight_to_start: Array[EnemyGroup] = []
				for enemy_data in template.enemies:
					var enemy_archetype = enemy_data.get("archetype", "Mountain Drake")
					var enemy_count = enemy_data.get("count", 1)
					var enemy_level = enemy_data.get("level", 1)
					var enemy_name = enemy_data.get("name", "")
					var enemy_portrait = enemy_data.get("portrait", -1)
					
					# Create the EnemyGroup from the data
					var new_enemy_group = EnemyGroup.from_enemy_data(enemy_archetype, enemy_level, enemy_count, enemy_name, enemy_portrait)
					fight_to_start.append(new_enemy_group) # Add the main enemy character to the list
				enter_fight(fight_to_start)
				return

	if event_id_or_choice_id == "radiant_quest_turn_in":
		var completed_quest = RadiantQuestManager.turn_in_quest()
		if completed_quest.is_empty():
			printerr("No completed radiant quest to turn in.")
			return

		_show_event_by_id("evt_" + self.curr_place + "_guild")
		return

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
	var placeholders: Dictionary = {}

	for outcome in outcomes:
		var outcome_type = outcome.get("type", "")

		if outcome.has("condition") and not GameState.check_complex_condition(outcome.condition, GameState.party):
			continue # Skip this outcome if its condition isn't met

		match outcome_type:
			"gold": # E.g., {"type": "gold", "change": 100}
				GameState.change_gold(outcome.change)
				placeholders["[RewardGold]"] = str(outcome.change)

			"xp": # E.g., {"type": "xp", "amount": 50}
				var xp_report = GameState.receive_experience(outcome.amount)
				placeholders["[QuestRewardSummary]"] = _format_xp_report_to_string(xp_report)

			"quest_update": # E.g., {"type": "quest_update", "quest_id": 1, "action": "accept/accomplish/turn"}
				var quest_id = outcome.quest_id
				match outcome.action:
					"accept": GameState.accept_quest(quest_id)
					"accomplish": GameState.accomplish_quest(quest_id)
					"turn": GameState.turn_quest(quest_id)
					
			"new_radiant_quest":
				var generated_quest = RadiantQuestManager.generate_quest(self.curr_place)
				if not generated_quest.is_empty():
					event_ui.show_dynamic_quest_offer(generated_quest)
				else:
					next_event_id_from_outcomes = "evt_guild_no_work_available"

			"turn_in_radiant_quest":
				var radiant_quest = RadiantQuestManager.get_active_quest()
				if not radiant_quest.is_empty():
					var template: RadiantQuestTemplate = radiant_quest.template as RadiantQuestTemplate

					GameState.change_gold(template.reward_gold)
					
					var xp_report = GameState.receive_experience(template.reward_xp)
					
					var summary_text = _format_xp_report_to_string(xp_report)
					
					var dynamic_placeholders = {
						"[QuestRewardSummary]": summary_text,
						"[RewardGold]": str(template.reward_gold),
						"[LocationName]": radiant_quest.poi_name,
						"[CityName]": radiant_quest.region_id.replace("_", " ").capitalize()
					}
					
					event_ui.show_dynamic_quest_turn_in(template.turn_in_description, radiant_quest.title, dynamic_placeholders)
				else:
					printerr("No active radiant quest to turn in.")

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
					var enemy_count = enemy_data.get("count", 1)
					var enemy_level = enemy_data.get("level", 1)
					var enemy_name = enemy_data.get("name", "")
					var enemy_portrait = enemy_data.get("portrait", -1)
					
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
			_:
				printerr("EventManager: Unknown outcome type: ", outcome_type)
				continue # Skip unknown types

	# After processing all conditional outcomes:
	if fight_to_start:
		enter_fight(fight_to_start)
	elif not next_event_id_from_outcomes.is_empty():
		if next_event_id_from_outcomes == "leave":
			leave_event()
		else:
			_show_event_by_id(next_event_id_from_outcomes, placeholders)
	else:
		 # If no "next_event" specified, and not a fight, assume error
		printerr("EventManager: No next event or fight to start. Leaving event.")


func _compare(val1, operator_str: String, val2) -> bool:
	match operator_str:
		"gte": return val1 >= val2
		"lte": return val1 <= val2
		"eq": return val1 == val2
	return false

func _format_xp_report_to_string(xp_report: Array[Dictionary]) -> String:
	var summary_lines: Array[String] = []
	var someone_leveled_up = false

	for report in xp_report:
		var line = "- %s gained %d XP." % [report.name, report.xp_gained]
		if report.leveled_up:
			line += " [color=yellow]Level Up![/color] (Now Level %d)" % report.new_level
			someone_leveled_up = true
		summary_lines.append(line)
	
	var final_text = "Your party receives their reward.\n" + "\n".join(summary_lines)
	
	if someone_leveled_up:
		final_text += "\n\n[b]Don't forget to spend your new skill points![/b]"
		
	return final_text

func _show_event_by_id(event_id: String, placeholders: Dictionary = {}):
	event_ui.show_event(curr_place, event_id, placeholders)


func random_event_manager(_event_content: Dictionary):
	var _party = GameState.party
	#TODO change party to whatever
	# event_ui.show_event("conversation", "conversation", party, true)
	# event_ui.visible = true
	# GameState.in_event = true


func enter_event(place_id: String):
	self.curr_place = place_id

	var active_quest: Dictionary = RadiantQuestManager.get_active_quest()

	if not active_quest.is_empty() and active_quest.template.quest_type != RadiantQuestTemplate.QuestType.DELIVER and active_quest.poi_event_id == place_id:
		event_ui.show_dynamic_quest_location_event(active_quest)
	else:
		event_ui.show_event(place_id, place_id)

	event_ui.visible = true
	GameState.in_event = true
	
func display_new_member():
	var candidate: PartyMember = PartyMember.new_rand()
	GameState.new_candidate(candidate)
	
	
func leave_event():
	event_ui.visible = false
	GameState.in_event = false
	
func enter_fight(enemy_group: Array[EnemyGroup]):
	fight_ui.visible = true
	fight_ui.update_ui(GameState.party, enemy_group)
	event_ui.visible = false
	
func exit_fight(victory: bool):
	fight_ui.visible = false
	
	event_ui.visible = true
	event_ui.current_event_json_data = {}
	
	var radiant_quest: Dictionary = RadiantQuestManager.get_active_quest()

	if not radiant_quest.is_empty() and radiant_quest.poi_event_id == curr_place and radiant_quest.state == "Accepted":
		if victory:
			RadiantQuestManager.complete_objective()
		event_ui.show_dynamic_quest_location_event(radiant_quest, true)
	else:
		var next_event = fight_victory_event_id if victory else fight_defeat_event_id
		event_manager(next_event)