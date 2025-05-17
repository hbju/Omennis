class_name EventManager

var event_ui: EventUI
var fight_ui: FightUI
var curr_fight: String

var curr_place = ""

func _init(_event_ui: EventUI, _fight_ui: FightUI) :
	self.event_ui = _event_ui
	self.fight_ui = _fight_ui
	event_ui.resolve_event.connect(event_manager)

func event_manager(event_id: String) : 
	match event_id : 
		"leave" :
			leave_event()
			
		# GALL	
		"evt_tavern_find_potential_companion" :
			display_new_member()
		"recruit_member" :
			GameState.change_gold(-100)
			GameState.recruit_candidate()
			event_ui.show_event(curr_place, "evt_gall_tavern_interior")
		"opt_quest_accept_cauldron_easy" :
			GameState.accept_quest(1)
			event_ui.show_event(curr_place, "evt_guild_noticeboard")
		"opt_quest_accept_hollow_hard" :
			GameState.accept_quest(2)
			event_ui.show_event(curr_place, "evt_guild_noticeboard")
		"opt_turn_in_quest_cauldron" : 
			GameState.turn_quest(1)
			GameState.change_gold(150)
			GameState.receive_experience(1500)
			event_ui.show_event(curr_place, "evt_guild_clerk_interaction")
		"opt_turn_in_quest_hollow" : 
			GameState.turn_quest(2)
			GameState.change_gold(400)
			GameState.receive_experience(4000)
			event_ui.show_event(curr_place, "evt_guild_clerk_interaction")
			
			
		# Cauldron Moutains
		"fight_drake_ambush" : 
			enter_fight(EnemyGroup.new("Mountain Drakes", Character.CLASSES.Warrior, 1, 2, 2), event_id)
		"evt_cauldron_prospector_found" :
			GameState.accomplish_quest(1)
			event_ui.show_event(curr_place, event_id)
			
		# Whispering Hollow
		"hollow_fight_first_cultists" : 
			enter_fight(EnemyGroup.new("Cultists", Character.CLASSES.Mage, 2, 2, 3), event_id)
		"hollow_fight_leader_and_cultists" : 
			enter_fight(EnemyGroup.new("Cultist Leader", Character.CLASSES.Mage, 2, 7, 1), event_id)
		"hollow_fight_leader_and_cultists_victory" : 
			GameState.accomplish_quest(2)
			event_ui.show_event(curr_place, event_id)

		_ : 
			event_ui.show_event(curr_place, event_id)

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
	var candidate_array: Array[PartyMember] = [candidate]
	event_ui.show_event(curr_place, "evt_tavern_find_potential_companion", candidate_array)
	
	
func leave_event() : 
	event_ui.visible = false
	GameState.in_event = false
	
func enter_fight(enemy_group: EnemyGroup, event_id: String) :
	fight_ui.visible = true
	fight_ui.update_ui(GameState.party, enemy_group)
	curr_fight = event_id
	event_ui.visible = false
	
func exit_fight(victory: bool) :
	fight_ui.visible = false
	var next_event = curr_fight + ("_victory" if victory else "_defeat")
	event_ui.visible = true
	event_manager(next_event)
