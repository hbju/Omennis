extends Control
class_name EventUI

@onready var bg_card = $bg
@onready var card_name_label = $bg/event_name/name
@onready var card_illustration = $bg/event_visual_border/event_visual
@onready var description_container = $bg/event_description/description_container
@onready var card_description_label: RichTextLabel = $bg/event_description/description_container/VBoxContainer/description_text
@onready var card_choice_buttons_control = $bg/event_description/description_container/VBoxContainer

var id: String
var possibilities: Array
var text_tween: Tween

var current_event_json_data: Dictionary

signal resolve_event(event_ccl)

const possibilities_height = 90
const possibilities_width = 256

func _ready():
	text_tween = get_tree().create_tween()
	show_event("gall", "gall")

		
func show_event(curr_place: String, event_id: String, placeholders: Dictionary = {}, random: bool = false):
	print("EventUI: Showing event '%s' in place '%s'" % [event_id, curr_place])
	if ResourceLoader.exists("res://assets/ui/events_ui/pictures/" + event_id + ".png"):
		card_illustration.texture = load("res://assets/ui/events_ui/pictures/" + event_id + ".png")
	elif ResourceLoader.exists("res://assets/ui/events_ui/pictures/" + event_id + ".jpg"):
		card_illustration.texture = load("res://assets/ui/events_ui/pictures/" + event_id + ".jpg")
	
	var place_json_data = get_event_data(curr_place, random).data

	var event_content = null
	for content in place_json_data.events:
		if content.id == event_id:
			event_content = content
			break

	if event_content == null:
		printerr("EventUI: Event ID '%s' not found in JSON data." % event_id)
		return

	current_event_json_data = event_content
	_display_event_text_and_possibilities(event_id, event_content, placeholders)

	
func show_dynamic_quest_offer(quest_data: Dictionary):
	# Clear any old buttons and state
	for old_possibility in card_choice_buttons_control.get_children():
		if old_possibility is Button:
			old_possibility.queue_free()
	
	var offer_text = quest_data.offer_description
	
	var event_content: Dictionary = {
		"name": quest_data.title,
		"description": offer_text,
		"possibilities": [
			{
				"id": "accept_radiant_quest",
				"description": "Accept the contract.",
				"outcome": {
					"type": "accept_radiant_quest",
				}
			},
			{
				"id": "decline_radiant_quest",
				"description": "Decline.",
				"outcome": {
					"type": "decline_radiant_quest",
				}
			}
		]
	}

	_display_event_text_and_possibilities(quest_data.id, event_content)


func show_dynamic_quest_turn_in(description: String, event_name: String, placeholders: Dictionary = {}):
	# Clear old buttons
	for old_possibility in card_choice_buttons_control.get_children():
		if old_possibility is Button:
			old_possibility.queue_free()

	var event_content: Dictionary = {
		"name": event_name,
		"description": description,
		"possibilities": [
			{
				"id": "radiant_quest_turn_in",
				"description": "Turn in the contract and go back to the guild hall.",
			}
		]
	}

	_display_event_text_and_possibilities(event_name, event_content, placeholders)

func show_dynamic_quest_location_event(quest_data: Dictionary, post_fight: bool = false):
	# Clear old buttons
	for old_possibility in card_choice_buttons_control.get_children():
		if old_possibility is Button:
			old_possibility.queue_free()

	var template = quest_data.template as RadiantQuestTemplate
	
	if ResourceLoader.exists("res://assets/ui/events_ui/pictures/" + quest_data.poi_event_id + ".png"):
		card_illustration.texture = load("res://assets/ui/events_ui/pictures/" + quest_data.poi_event_id + ".png")
	elif ResourceLoader.exists("res://assets/ui/events_ui/pictures/" + quest_data.poi_event_id + ".jpg"):
		card_illustration.texture = load("res://assets/ui/events_ui/pictures/" + quest_data.poi_event_id + ".jpg")

	if not post_fight:
		var pre_text = template.location_entry_description\
			.replace("[LocationName]", quest_data.poi_name)\
			.replace("[CityName]", quest_data.region_id.replace("_", " ").capitalize())\
			.replace("[RewardGold]", str(quest_data.template.reward_gold))

		var event_content: Dictionary = {
			"name": quest_data.poi_name,
			"description": pre_text,
			"possibilities": [
				{
					"id": "start_radiant_fight",
					"description": "Confront the threat.",
					"outcome": "start_radiant_fight"
				},
				{
					"id": "leave",
					"description": "Leave the area."
				}
			]
		}

		_display_event_text_and_possibilities(quest_data.poi_event_id, event_content)


	elif quest_data.state == "Accomplished":
		# --- POST-OBJECTIVE STATE, VICTORY ---
		var post_text = template.location_post_objective_victory_description\
			.replace("[LocationName]", quest_data.poi_name)\
			.replace("[CityName]", quest_data.region_id.capitalize())\
			.replace("[RewardGold]", str(quest_data.template.reward_gold))

		var event_content: Dictionary = {
			"name": quest_data.poi_name,
			"description": post_text,
			"possibilities": [
				{
					"id": "leave",
					"description": "Leave the area."
				}
			]
		}
		_display_event_text_and_possibilities(quest_data.poi_event_id, event_content)

	elif quest_data.state == "Accepted":
		# --- POST-OBJECTIVE STATE, FAILURE ---
		var post_text = template.location_post_objective_failure_description\
			.replace("[LocationName]", quest_data.poi_name)\
			.replace("[CityName]", quest_data.region_id.capitalize())\
			.replace("[RewardGold]", str(quest_data.template.reward_gold))

		var event_content: Dictionary = {
			"name": quest_data.poi_name,
			"description": post_text,
			"possibilities": [
				{
					"id": "leave",
					"description": "Leave the area."
				}
			]
		}
		
		_display_event_text_and_possibilities(quest_data.poi_event_id, event_content)


func get_event_data(curr_place: String, random: bool = false) -> Resource:
	# Define base search paths
	var base_path = "res://text/events/"
	var random_base_path = base_path.path_join("random_events") # "res://text/events/random_events"
	var target_filename = curr_place + ".json"

	var found_path = ""

	if random:
		found_path = _find_file_recursively(random_base_path, target_filename)
	else:
		found_path = _find_file_recursively(base_path, target_filename)


	if found_path.is_empty():
		if random:
			found_path = _find_file_recursively(base_path, target_filename)

	if not found_path.is_empty():
		if ResourceLoader.exists(found_path): # Double-check existence before loading
			return load(found_path)
		else:
			printerr("File path found but ResourceLoader says it doesn't exist: ", found_path)
			return null
	else:
		printerr("Event file '%s' not found in event directories." % target_filename)
		return null


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			AudioManager.play_sfx(AudioManager.UI_BUTTON_CLICK)
			text_tween.stop()
			card_description_label.visible_ratio = 1
			_show_possibilities()

##
## Recursive function to search for a file in a directory and its subdirectories 
## Returns the full path if found, or an empty string if not found
##
func _find_file_recursively(search_dir: String, filename_to_find: String) -> String:
	var dir = DirAccess.open(search_dir)

	if not dir:
		return "" # Return empty, just means not found here

	# Check if the file exists directly in the current directory
	var direct_path = search_dir.path_join(filename_to_find)
	if FileAccess.file_exists(direct_path):
		return direct_path # Found it!

	# If not found directly, search subdirectories
	dir.list_dir_begin()
	var item_name = dir.get_next()
	while item_name != "":
		if item_name != "." and item_name != "..": # Skip navigation entries
			if dir.current_is_dir():
				var subdir_path = search_dir.path_join(item_name)
				var found_in_subdir = _find_file_recursively(subdir_path, filename_to_find)
				if not found_in_subdir.is_empty():
					dir.list_dir_end()
					return found_in_subdir
		item_name = dir.get_next()

	dir.list_dir_end()

	return ""
		
func on_possibilities_buttons_pressed(event_conclusion: String):
	resolve_event.emit(event_conclusion)
	
func _process_dynamic_text(raw_text: String, placeholders: Dictionary) -> String:
	var new_text = raw_text

	# First, process the party member names like before
	for i in range(GameState.party.size()):
		var member = GameState.party[i]
		new_text = new_text.replace("[char%d]" % i, member.character_name)
		# Add other [he/she/they] replacements here if needed

	for key in placeholders:
		new_text = new_text.replace(key, placeholders[key])
		
	return new_text
	
func _display_event_text_and_possibilities(event_id: String, event_content: Dictionary, placeholders: Dictionary = {}): 
	self.id = event_id
	
	card_name_label.text = event_content.name

	card_description_label.text = _process_dynamic_text(event_content.description, placeholders)
	card_description_label.set_size(Vector2(750, 0))
	card_description_label.visible_ratio = 0
	text_tween.kill()
	text_tween = get_tree().create_tween()
	text_tween.tween_property(card_description_label, "visible_ratio", 1, card_description_label.text.length() / 100.0)
	text_tween.tween_callback(_show_possibilities).set_delay(0.3)
	
	description_container.get_v_scroll_bar().ratio = 0
	for old_possibility in card_choice_buttons_control.get_children():
		if old_possibility is Button:
			old_possibility.queue_free()
	
	self.possibilities = event_content.possibilities
	
	for i in range(possibilities.size()):
		if not possibilities[i].has("condition") or GameState.conditions(possibilities[i].condition):
			var possibility_button: Button = Button.new()
			card_choice_buttons_control.add_child(possibility_button)

			possibility_button.text = _process_dynamic_text(possibilities[i].description, placeholders)

			possibility_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			possibility_button.custom_minimum_size = Vector2(possibilities_width, possibilities_height)
			
			possibility_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
			possibility_button.pressed.connect(on_possibilities_buttons_pressed.bind(possibilities[i].id))

			possibility_button.hide()

					
	card_description_label.position.y = 0

func _show_possibilities():
	for button in card_choice_buttons_control.get_children():
		if button is Button:
			button.show()
