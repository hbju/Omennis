# RadiantQuestManager.gd
extends Node

var pending_radiant_quest: Dictionary = {}
var active_radiant_quest: Dictionary = {}

# We'll load all our templates at the start of the game.
var quest_templates: Array[RadiantQuestTemplate] = []

func _ready():
	_load_all_templates("res://text/quests/radiant_quests/")

# This function finds all .tres files of our template type in a folder.
func _load_all_templates(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		printerr("RadiantQuestManager: Could not open path: ", path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var template = load(path.path_join(file_name))
			if template is RadiantQuestTemplate:
				quest_templates.append(template)
		file_name = dir.get_next()
	
	print("RadiantQuestManager: Loaded %d quest templates." % quest_templates.size())

# --- The Core Generation Function ---
func generate_quest(region_id: String) -> Dictionary:
	if not active_radiant_quest.is_empty():
		print("A radiant quest is already active.")
		return active_radiant_quest

	# 1. Find a suitable template
	if quest_templates.is_empty():
		printerr("No radiant quest templates loaded!")
		return {}
	
	var template_candidates = quest_templates.duplicate(true)
	template_candidates.shuffle() # Randomize templates for variety
	var valid_template_found = false
	
	var chosen_template: RadiantQuestTemplate = null
	var chosen_poi: PointOfInterest = null

	var party = GameState.party
	var min_level = -1
	var avg_level = 0
	for member in party:
		avg_level += member.character_level
		if member.character_level > min_level:
			min_level = member.character_level
	avg_level = avg_level / party.size()

	template_candidates = template_candidates.filter(func(t): return (t.min_player_level <= min_level and t.min_player_level >= avg_level))
	print("Filtered templates by player level (", min_level, ") found ", template_candidates.size(), " templates available.")

	while (not valid_template_found) and not template_candidates.is_empty():
		chosen_template = template_candidates.pop_front() 
		print("Trying template: ", chosen_template.quest_id_prefix)

		# 2. Find all POIs for the given city/region
		var all_pois = get_tree().get_nodes_in_group("points_of_interest")
		var valid_pois: Array[PointOfInterest] = []
		for poi in all_pois:
			if chosen_template.quest_type == RadiantQuestTemplate.QuestType.DELIVER :
				if poi.tags.has("city") and poi.region_id != region_id:
					valid_pois.append(poi) # Deliver quests can be to any city POI
			elif poi.region_id == region_id:
				valid_pois.append(poi)
		valid_pois.shuffle() # Randomize the order for variety
		
		if valid_pois.is_empty():
			printerr("No valid POIs found for region: ", region_id)
			return {}

		print("Found %d valid POIs for region: %s" % [valid_pois.size(), region_id])

		# 3. Find a POI that matches the template's tag requirement
		for poi in valid_pois.filter(func(p): 
			for tag in chosen_template.location_tag_required:
				if p.tags.has(tag):
					return true
			return false
				):
			chosen_poi = poi
			break # Found one, stop looking

		if chosen_poi:
			valid_template_found = true
		else:
			print("No suitable POI found for template: ", chosen_template.quest_id_prefix)
			chosen_template = null # Reset to try the next template

	# 4. Bake the final quest from the template and POI data
	var quest_id = "%s_%d" % [chosen_template.quest_id_prefix, Time.get_unix_time_from_system()]
	var title = chosen_template.title_template\
			.replace("[LocationName]", chosen_poi.poi_name)\
			.replace("[CityName]", chosen_poi.region_id.capitalize())
	var description = chosen_template.description_template\
			.replace("[LocationName]", chosen_poi.poi_name)\
			.replace("[CityName]", chosen_poi.region_id.capitalize())\
			.replace("[RewardGold]", str(chosen_template.reward_gold))\
			.replace("[LocationDistance]", str(GameState.get_distance_and_orientation_to_location(region_id.replace("_", " ").capitalize(), chosen_poi)))

	var offer_description = chosen_template.offer_description\
		.replace("[LocationName]", chosen_poi.poi_name)\
		.replace("[CityName]", chosen_poi.region_id.replace("_", " ").capitalize())\
		.replace("[RewardGold]", str(chosen_template.reward_gold))\
		.replace("[LocationDistance]", str(GameState.get_distance_and_orientation_to_location(region_id.replace("_", " ").capitalize(), chosen_poi)))

	pending_radiant_quest = {
		"id": quest_id,
		"title": title,
		"description": description,
		"offer_description": offer_description,
		"state": "Accepted" if chosen_template.quest_type != RadiantQuestTemplate.QuestType.DELIVER else "Accomplished", # States: Accepted, Accomplished, Turned_In
		"template": chosen_template,
		"poi_name": chosen_poi.poi_name,
		"poi_event_id": chosen_poi.event_id_on_enter,
		"region_id": region_id if chosen_template.quest_type != RadiantQuestTemplate.QuestType.DELIVER else chosen_poi.region_id
	}
	
	print("Generated Radiant Quest: ", pending_radiant_quest.title)
	return pending_radiant_quest

func finalize_quest_acceptance():
	if pending_radiant_quest.is_empty(): return
	active_radiant_quest = pending_radiant_quest.duplicate()
	pending_radiant_quest.clear()
	print("Radiant quest accepted: ", active_radiant_quest.title)

func clear_pending_quest():
	pending_radiant_quest.clear()

func get_active_quest() -> Dictionary:
	return active_radiant_quest

func complete_objective():
	if active_radiant_quest.is_empty(): return
	active_radiant_quest.state = "Accomplished"
	print("Radiant quest objective completed!")

func turn_in_quest() -> Dictionary:
	if active_radiant_quest.is_empty() or active_radiant_quest.state != "Accomplished":
		return {}
	
	var completed_quest = active_radiant_quest.duplicate()
	active_radiant_quest.clear()
	print("Radiant quest turned in!")
	return completed_quest
