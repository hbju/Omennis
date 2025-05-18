extends TileMap
class_name Overworld

@onready var player = $player
var player_cell: Vector2i = Vector2i(0, 0)
var player_neighbours: Array[Vector2i] = []

@onready var gall = $gall
@onready var cauldron_mountains = $cauldron_mountains
@onready var whispering_hollow = $whispering_hollow

@onready var party_ui: PartyUI = $UI/party_ui
@onready var quest_log_ui: QuestLogUI = $UI/quest_log_ui
@onready var skill_ui: SkillUI = $UI/skill_ui
@onready var gold_amount = $UI/gold/gold_amount

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
	event_manager = EventManager.new($UI/event_ui, $UI/fight_ui)
	quest_manager = QuestManager.new()

	player.target_reached.connect(_on_target_reached)
	_on_target_reached()

	gall.body_entered.connect(_toggle_event_ui.bind("gall"))
	cauldron_mountains.body_entered.connect(_toggle_event_ui.bind("cauldron_mountains"))
	whispering_hollow.body_entered.connect(_toggle_event_ui.bind("whispering_hollow"))

	$UI/party_button.pressed.connect(_toggle_party_ui)
	$UI/party_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_SCREEN_OPEN))

	$UI/quest_log_button.pressed.connect(_toggle_questlog_ui)
	$UI/quest_log_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_SCREEN_OPEN))

	party_ui.fire_character.connect(_on_fire_character)
	party_ui.show_skill_tree.connect(_on_show_skill_tree)

	ContentGenerator.content_received.connect(_on_content_received)
	var initial_random_event_prompt = "Generate a random event for the following party of adventurers : "
	for i in range(GameState.party.size()) :
		initial_random_event_prompt += "\n" + GameState.party[i].to_string()
	ContentGenerator.request_content(initial_random_event_prompt)

	GameState.random_event.connect(_on_random_event)
	GameState.money_changed.connect(_on_money_changed)
	GameState.change_gold(1000)
	
	if testing :
		GameState.accept_quest(1)
		GameState.new_candidate(PartyMember.new_rand())
		GameState.recruit_candidate()
		GameState.receive_experience(50000)

func oddr_offset_neighbor(hex, direction):
	var parity = hex.y & 1
	var diff = oddr_direction_differences[parity][direction]
	return Vector2i(hex.x + diff[0], hex.y + diff[1])
	
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
	if GameState.in_event or GameState.in_ui :
		return

	if event is InputEventMouseMotion :
		var mouse_cell = local_to_map(to_local(get_global_mouse_position()))
		if mouse_cell in player_neighbours :
			highlight_neighbours(1)
			if can_walk(mouse_cell) :
				set_cell(0, mouse_cell, 22, get_cell_atlas_coords(0, mouse_cell), 2)


	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var click_cell = local_to_map(to_local(get_global_mouse_position()))
			if is_neighbour(player_cell, click_cell) && can_walk(click_cell): 
				player.move_to(map_to_local(click_cell))
				GameState.step_taken()

func toggle_ui(state: bool) : 
	$UI.visible = state

func disable_collisions(state: bool) : 
	$gall/CollisionShape2D.disabled = state
	$cauldron_mountains/CollisionShape2D.disabled = state
	$whispering_hollow/CollisionShape2D.disabled = state
	$player/CollisionShape2D.disabled = state

func highlight_neighbours(empty_cell_alt: int = 0) -> void:
	for neighbour in player_neighbours :
		set_cell(0, neighbour, 22, get_cell_atlas_coords(0, neighbour), empty_cell_alt)

func _toggle_event_ui(_body, place_id: String): 
	event_manager.enter_event(place_id)
	
func _toggle_party_ui(): 
	party_ui.update_ui(GameState.party)
	if not party_ui.visible :  
		party_ui.visible = true
		GameState.in_ui = true
	else :
		party_ui.visible = false
		GameState.in_ui = false
	quest_log_ui.visible = false
	
func _toggle_questlog_ui() :
	quest_log_ui.update_ui(GameState.quest_log)
	if not quest_log_ui.visible :  
		quest_log_ui.visible = true
		GameState.in_ui = true
	else :
		quest_log_ui.visible = false
		GameState.in_ui = false
	party_ui.visible = false

func _on_target_reached() :
	highlight_neighbours(0)
	player_cell = local_to_map(to_local(player.global_position))
	player_neighbours = []
	for i in range(0, 6) :
		var neighbour = oddr_offset_neighbor(player_cell, i)
		player_neighbours.append(neighbour)
	highlight_neighbours(1)
	
func _on_fire_character(index: int) : 
	GameState.fire_member(index)
	party_ui.update_ui(GameState.party)

func _on_show_skill_tree(index: int) : 
	skill_ui.update_ui(GameState.party[index])
	skill_ui.visible = true

func _on_content_received(data: Dictionary) :
	next_random_event = data
	
func _on_random_event() : 
	# if next_random_event.is_empty() :
	#	print("No random event available")
	#	return
	
	event_manager.random_event_manager(next_random_event)
	next_random_event = {}

	var party = GameState.party
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
	context_info += "Current money: " + str(GameState.party_money) + "g"
	context_info += "\n\n"
	context_info += "Current quests: \n"
	for quest in GameState.quest_log.keys() : 
		var quest_info = load("res://text/quests/" + "%03d" % quest + ".json").data
		context_info += "\n" + quest_info.name + "\n"
		context_info += "Difficulty: {difficulty} \n" + \
			"Location: {location} \n" + \
			"Description: {description} \n" + \
			"Reward: {reward} \n".format({"difficulty" : quest_info.difficulty, "location" : quest_info.location,
			"description": quest_info.description, "reward": quest_info.reward})


	ContentGenerator.request_content(prompt, context_info)
	
func _on_money_changed() : 
	gold_amount.text = str(GameState.party_money) + "g"
