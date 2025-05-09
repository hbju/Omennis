class_name EventManager

var event_ui: EventUI
var fight_ui: FightUI
var game_state: GameState
var curr_fight: String

var curr_place = ""

func _init(_event_ui: EventUI, _fight_ui: FightUI, _game_state: GameState) :
	self.event_ui = _event_ui
	self.fight_ui = _fight_ui
	event_ui.resolve_event.connect(event_manager)
	self.game_state = _game_state

func event_manager(event_id: String) : 
	match event_id : 
		"leave" :
			leave_event()
			
		# GALL	
		"evt_tavern_find_potential_companion" :
			display_new_member()
		"recruit_member" :
			game_state.change_gold(-100)
			game_state.recruit_candidate()
			event_ui.show_event(curr_place, "evt_gall_tavern_interior")
		"opt_quest_accept_cauldron_easy" :
			game_state.accept_quest(1)
			event_ui.show_event(curr_place, "evt_guild_noticeboard")
		"opt_quest_accept_hollow_hard" :
			game_state.accept_quest(2)
			event_ui.show_event(curr_place, "evt_guild_noticeboard")
		"opt_turn_in_quest_cauldron" : 
			game_state.turn_quest(1)
			game_state.change_gold(150)
			game_state.receive_experience(1500)
			event_ui.show_event(curr_place, "evt_guild_clerk_interaction")
		"opt_turn_in_quest_hollow" : 
			game_state.turn_quest(2)
			game_state.change_gold(400)
			game_state.receive_experience(4000)
			event_ui.show_event(curr_place, "evt_guild_clerk_interaction")
			
			
		# Cauldron Moutains
		"fight_drake_ambush" : 
			enter_fight(EnemyGroup.new("Mountain Drakes", Character.CLASSES.Warrior, 1, 2, 2), event_id)
		"evt_cauldron_prospector_found" :
			game_state.accomplish_quest(1)
			event_ui.show_event(curr_place, event_id)
			
		# Whispering Hollow
		"hollow_fight_first_cultists" : 
			enter_fight(EnemyGroup.new("Cultists", Character.CLASSES.Mage, 2, 2, 3), event_id)
		"hollow_fight_leader_and_cultists" : 
			enter_fight(EnemyGroup.new("Cultist Leader", Character.CLASSES.Mage, 2, 7, 1), event_id)
		"hollow_fight_leader_and_cultists_victory" : 
			game_state.accomplish_quest(2)
			event_ui.show_event(curr_place, event_id)

		_ : 
			event_ui.show_event(curr_place, event_id)

func random_event_manager(_event_content: Dictionary) : 
	var party = game_state.party
	#TODO change party to whatever
	# event_ui.show_event("conversation", "conversation", party, true)
	# event_ui.visible = true
	# game_state.in_event = true


func enter_event(place_id: String) :
	self.curr_place = place_id

	event_ui.show_event(place_id, place_id)
	event_ui.visible = true
	game_state.in_event = true
	
func display_new_member() :
	var candidate: PartyMember = PartyMember.new_rand()
	game_state.new_candidate(candidate)
	var candidate_array: Array[PartyMember] = [candidate]
	event_ui.show_event(curr_place, "evt_tavern_find_potential_companion", candidate_array)
	
	
func leave_event() : 
	event_ui.visible = false
	game_state.in_event = false
	
func enter_fight(enemy_group: EnemyGroup, event_id: String) :
	fight_ui.visible = true
	fight_ui.update_ui(game_state.party, enemy_group)
	curr_fight = event_id
	event_ui.visible = false
	
func exit_fight(victory: bool) :
	fight_ui.visible = false
	var next_event = curr_fight + ("_victory" if victory else "_defeat")
	event_ui.visible = true
	event_manager(next_event)
