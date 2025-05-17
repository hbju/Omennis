extends Control
class_name EventUI

@onready var bg_card = $bg
@onready var card_name_label = $bg/event_name/name
@onready var card_illustration = $bg/event_visual
@onready var description_container = $bg/event_description/description_container
@onready var card_description_label = $bg/event_description/description_container/VBoxContainer/description_text
@onready var card_choice_buttons_control = $bg/event_description/description_container/VBoxContainer

var id: String
var event_name: String
var event_description: String
var possibilities: Array
var event_path: Array[String]

signal resolve_event(event_ccl)

const possibilities_height = 90
const possibilities_width = 256

func _ready():
	show_event("gall", "gall")

		
func show_event(curr_place: String, event_id: String, characters: Array[PartyMember] = [], random: bool = false) :
	if ResourceLoader.exists("res://assets/ui/events_ui/pictures/" + event_id + ".png") :
		card_illustration.texture = load("res://assets/ui/events_ui/pictures/" + event_id + ".png")
	var place_content = get_event_data(curr_place, random).data 


	var event_content = null
	for content in place_content.events:
		if content.id == event_id:
			event_content = content
			break
	self.id = event_id
	
	card_name_label.text = event_content.name
	
	card_description_label.text = process_text(event_content.description, characters)
	card_description_label.set_size(Vector2(550, 0))
	
	description_container.get_v_scroll_bar().ratio = 0
	for old_possibility in card_choice_buttons_control.get_children() :
		if old_possibility is Button: 
			old_possibility.queue_free()
	
	self.possibilities = event_content.possibilities
	
	for i in range(possibilities.size()) :
		if not possibilities[i].has("condition") or GameState.conditions(possibilities[i].condition) :
			var possibility_button: Button = Button.new()
			card_choice_buttons_control.add_child(possibility_button)

			possibility_button.text = process_text(possibilities[i].description, characters)

			possibility_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			possibility_button.custom_minimum_size = Vector2(possibilities_width, possibilities_height)
			
			possibility_button.pressed.connect(on_possibilities_buttons_pressed.bind(possibilities[i].id))
			possibility_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
			
					
	card_description_label.position.y = 0
	
func get_event_data(curr_place: String, random: bool = false) -> Resource :
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
		
func on_possibilities_buttons_pressed(event_conclusion: String) :
	resolve_event.emit(event_conclusion)
	
func process_text(raw_text: String, party: Array[PartyMember]) -> String:
	var new_text: String = raw_text
	for i  in range(0, party.size()):
		new_text = new_text.replace("[Name " + str(i) + "]", party[i].character_name)
		new_text = new_text.replace("[Class " + str(i) + "]", party[i].get_char_class())
		new_text = new_text.replace("[he/she/they " + str(i) + "]", "he" if party[i].character_sex == PartyMember.SEX.Male else "she" if party[i].character_sex == PartyMember.SEX.Female else "they")
		new_text = new_text.replace("[his/her/their " + str(i) + "]", "his" if party[i].character_sex == PartyMember.SEX.Male else "her" if party[i].character_sex == PartyMember.SEX.Female else "their")
		new_text = new_text.replace("[him/her/them " + str(i) + "]", "him" if party[i].character_sex == PartyMember.SEX.Male else "her" if party[i].character_sex == PartyMember.SEX.Female else "them")
	return new_text
	


