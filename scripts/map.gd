extends TileMap

@onready var player = $player
@onready var gall = $gall
@onready var cauldron_mountains = $cauldron_mountains
@onready var whispering_hollow = $whispering_hollow
@onready var party_ui: PartyUI = $UI/party_ui
@onready var quest_log_ui: QuestLogUI = $UI/quest_log_ui
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

func _ready():
	event_manager = EventManager.new($UI/event_ui, $UI/fight_ui, game_state)
	quest_manager = QuestManager.new()
	gall.body_entered.connect(_toggle_event_ui.bind("gall"))
	cauldron_mountains.body_entered.connect(_toggle_event_ui.bind("cauldron_mountains"))
	whispering_hollow.body_entered.connect(_toggle_event_ui.bind("whispering_hollow"))
	$UI/party_button.pressed.connect(_toggle_party_ui)
	$UI/quest_log_button.pressed.connect(_toggle_questlog_ui)
	party_ui.fire_character.connect(_on_fire_character)
	game_state.random_event.connect(_on_random_event)
	game_state.money_changed.connect(_on_money_changed)
	game_state.change_gold(100)
	
	if testing :
		game_state.accept_quest(1)
		game_state.new_candidate(Character.new_rand())
		game_state.recruit_candidate()

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
	
func _on_random_event() : 
	event_manager.random_event_manager()
	
func _on_money_changed() : 
	gold_amount.text = str(game_state.party_money) + "g"
