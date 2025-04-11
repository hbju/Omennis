class_name EventManager

var event_ui: EventUI
var fight_ui: FightUI
var game_state: GameState
var curr_fight: String

func _init(_event_ui: EventUI, _fight_ui: FightUI, _game_state: GameState) :
	self.event_ui = _event_ui
	self.fight_ui = _fight_ui
	event_ui.resolve_event.connect(event_manager)
	fight_ui.resolve_fight.connect(exit_fight)
	self.game_state = _game_state

func event_manager(event_id: String) : 
	match event_id : 
		"leave" :
			leave_event()
			
		# GALL	
		"gall_new_member" :
			display_new_member()
		"recruit_member" :
			game_state.change_gold(-100)
			game_state.recruit_candidate()
			event_ui.show_event("gall_tavern")
		"gall_easy_quest" :
			game_state.accept_quest(1)
			event_ui.show_event(event_id)
		"gall_hard_quest" :
			game_state.accept_quest(2)
			event_ui.show_event(event_id)
		"gall_turn_easy_quest" : 
			game_state.turn_quest(1)
			game_state.change_gold(50)
			game_state.receive_experience(1500)
			event_ui.show_event(event_id)
		"gall_turn_hard_quest" : 
			game_state.turn_quest(2)
			game_state.change_gold(150)
			game_state.receive_experience(4000)
			event_ui.show_event(event_id)
			
			
		# Cauldron Moutains
		"cm_fight" : 
			enter_fight(EnemyGroup.new("Mountain Drakes", Character.CLASSES.None, 1, 2, 2), event_id)
		"cm_fight_victory" :
			game_state.accomplish_quest(1)
			event_ui.show_event(event_id)
			game_state.receive_experience(500)
		"cm_fight_defeat" : 
			game_state.receive_experience(200)
			event_ui.show_event(event_id)
			
		# Whispering Hollow
		"wh_first_fight" : 
			enter_fight(EnemyGroup.new("Cultists", Character.CLASSES.Mage, 2, 2, 3), event_id)
		"wh_first_fight_victory" : 
			game_state.receive_experience(1000)
			event_ui.show_event(event_id)
		"wh_first_fight_defeat" : 
			game_state.receive_experience(400)
			event_ui.show_event(event_id)
		"wh_leader_fight" : 
			enter_fight(EnemyGroup.new("Cultist Leader", Character.CLASSES.Mage, 2, 7, 1), event_id)
		"wh_leader_fight_victory" : 
			game_state.accomplish_quest(2)
			game_state.receive_experience(1000)
			event_ui.show_event(event_id)
		"wh_leader_fight_defeat" :
			game_state.receive_experience(400)
			event_ui.show_event(event_id)

		_ : 
			event_ui.show_event(event_id)

func random_event_manager(event_content: Dictionary) : 
	var party = game_state.party
	#TODO change party to whatever
	event_ui.show_event("conversation", party, true)
	event_ui.visible = true
	game_state.in_event = true


func enter_event(event_id: String) :
	event_ui.show_event(event_id)
	event_ui.visible = true
	game_state.in_event = true
	
func display_new_member() :
	var candidate: PartyMember = PartyMember.new_rand()
	game_state.new_candidate(candidate)
	var candidate_array: Array[PartyMember] = [candidate]
	event_ui.show_event("gall_new_member", candidate_array)
	
	
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
