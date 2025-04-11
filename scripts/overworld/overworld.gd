extends TileMap
class_name Overworld

@onready var player = $player
@onready var gall = $gall
@onready var cauldron_mountains = $cauldron_mountains
@onready var whispering_hollow = $whispering_hollow
@onready var party_ui: PartyUI = $UI/party_ui
@onready var quest_log_ui: QuestLogUI = $UI/quest_log_ui
@onready var skill_ui: SkillUI = $UI/skill_ui
@onready var gold_amount = $UI/gold/gold_amount
@onready var game_state: GameState = $"/root/game_state"
@onready var content_generator: ContentGenerator = $"/root/content_generator"
@onready var event_manager: EventManager
@onready var quest_manager: QuestManager

@export var testing = false

var oddr_direction_differences = [
	[[+1,  0], [ 0, -1], [-1, -1], 
	 [-1,  0], [-1, +1], [ 0, +1]],
	
	[[+1,  0], [+1, -1], [ 0, -1], 
	 [-1,  0], [ 0, +1], [+1, +1]],
]

var nature_walkable_cells = [0, 1, 2, 6, 7, 8, 9, 10, 11, 14, 15, 16]

var next_random_event: Dictionary

func _ready():
	event_manager = EventManager.new($UI/event_ui, $UI/fight_ui, game_state)
	quest_manager = QuestManager.new()

	gall.body_entered.connect(_toggle_event_ui.bind("gall"))
	cauldron_mountains.body_entered.connect(_toggle_event_ui.bind("cauldron_mountains"))
	whispering_hollow.body_entered.connect(_toggle_event_ui.bind("whispering_hollow"))

	$UI/party_button.pressed.connect(_toggle_party_ui)
	$UI/quest_log_button.pressed.connect(_toggle_questlog_ui)

	party_ui.fire_character.connect(_on_fire_character)
	party_ui.show_skill_tree.connect(_on_show_skill_tree)

	content_generator.content_received.connect(_on_content_received)
	var initial_random_event_prompt = "Generate a random event for the following party of adventurers : "
	for i in range(game_state.party.size()) :
		initial_random_event_prompt += "\n" + game_state.party[i].to_string()
	content_generator.request_content(initial_random_event_prompt)

	game_state.random_event.connect(_on_random_event)
	game_state.money_changed.connect(_on_money_changed)
	game_state.change_gold(100)
	
	if testing :
		game_state.accept_quest(1)
		game_state.new_candidate(PartyMember.new_rand())
		game_state.recruit_candidate()
		game_state.receive_experience(50000)

func oddr_offset_neighbor(hex, direction):
	var parity = hex.y & 1
	var diff = oddr_direction_differences[parity][direction]
	return Vector2(hex.x + diff[0], hex.y + diff[1])
	
func is_neighbour(hex, pos) : 
	var parity = hex.y & 1
	for i in range(0, 6) :
		var diff = oddr_direction_differences[parity][i]
		if Vector2i(hex.x + diff[0], hex.y + diff[1]) == pos : 
			return true
	return false
	
func can_walk(hex) : 
	return get_cell_source_id(0, hex) == 22 && get_cell_atlas_coords(0, hex).x in nature_walkable_cells
	
func _input(event):
	if game_state.in_event or game_state.in_ui :
		return
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var click_pos = local_to_map(to_local(get_global_mouse_position()))
			var player_pos = local_to_map(to_local(player.global_position))
			
			if is_neighbour(player_pos, click_pos) && can_walk(click_pos): 
				player.move_to(map_to_local(click_pos))
				game_state.step_taken()

func toggle_ui(state: bool) : 
	$UI.visible = state
	
func _toggle_event_ui(_body, event_id: String): 
	event_manager.enter_event(event_id)
	
func _toggle_party_ui(): 
	party_ui.update_ui(game_state.party)
	party_ui.visible = not party_ui.visible
	quest_log_ui.visible = false
	game_state.in_ui = not game_state.in_ui
	
func _toggle_questlog_ui() :
	quest_log_ui.update_ui(game_state.quest_log)
	quest_log_ui.visible = not quest_log_ui.visible
	party_ui.visible = false
	game_state.in_ui = not game_state.in_ui
	
func _on_fire_character(index: int) : 
	game_state.fire_member(index)
	party_ui.update_ui(game_state.party)

func _on_show_skill_tree(index: int) : 
	skill_ui.update_ui(game_state.party[index])
	skill_ui.visible = true

func _on_content_received(data: Dictionary) :
	next_random_event = data
	
func _on_random_event() : 
	# if next_random_event.is_empty() :
	#	print("No random event available")
	#	return
	
	event_manager.random_event_manager(next_random_event)
	next_random_event = {}

	var party = game_state.party
	var prompt = """
	You are a creative game event generator for the Party RPG Omennis.
	Generate a brief but flavorful random event suitable for occurring during travel or at camp.
	The event should primarily feature an interaction between two party members, using placeholders like `[Name 0]` and `[Name 1]`.
	Make the event concise and entertaining, allowing for varied tones like tension, drama, humor, bonding, or discovery.

	The event description must lead into 2-3 distinct player choices ('possibilities').
	For each possibility, provide:
	- The id of the choice, which must always be `leave`, which means that the event is only a single panel.
	- A short `description` of the choice presented to the player.

	Ensure your final output will contain values for:
	- A unique event `id` (lowercase_snake_case, e.g., 'campfire_argument').
	- A short event `name` (Title Case, e.g., 'Heated Words').
	- The main event `description` (using the placeholders `[Name 0]` and `[Name 1]`).
	- The array named `possibilities` containing the choices as described above.
	"""
	var context_info = "The party consists of the following characters: \n"
	for i in range(party.size()) :
		context_info += "\n" + party[i]._to_string()
		context_info += "\n\n"
	context_info += "Current money: " + str(game_state.party_money) + "g"
	context_info += "\n\n"
	context_info += "Current quests: \n"
	for j in range(game_state.quest_log.size()) :
		context_info += game_state.quest_log[j]._to_string()
		context_info += "\n\n"

	content_generator.request_content(prompt, context_info)
	
func _on_money_changed() : 
	gold_amount.text = str(game_state.party_money) + "g"
