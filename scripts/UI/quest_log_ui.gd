extends Control
class_name QuestLogUI

@onready var displayed_quest = $bg/displayed_quest
@onready var displayed_quest_title = $bg/displayed_quest/quest_title_bg/quest_title
@onready var displayed_quest_description = $bg/displayed_quest/quest_description_container/quest_description
@onready var quests_control = $bg/quests_scroll/quests_control

var quests_info: Array[Dictionary]

const QUESTS_HEIGHT = 70
const QUESTS_WIDTH = 500
const QUESTS_MARGIN = 20

var curr_quest: int

func update_ui(quest_log: Dictionary) :
	quests_info.clear()
	for quest_button in quests_control.get_children() :
		quest_button.queue_free()
	displayed_quest.visible = false
	
	curr_quest = 0
	for i in range(0, quest_log.size()):
		var quest_state = quest_log[quest_log.keys()[i]]
		if quest_state != GameState.QUEST_STATE.Turned :  
			var quest_info = load("res://text/quests/" + "%s" % quest_log.keys()[i] + ".json").data
			quests_info.append(quest_info)
			
			var quest_button = Button.new()
			quest_button.add_theme_color_override("font_color", Color(0, 0, 0))
			quest_button.add_theme_font_size_override("font_size", 30)
			var quest_title = quest_info.name + (" (Accomplished)" if quest_state == GameState.QUEST_STATE.Accomplished else "") 
			quest_button.set_text(quest_title)
			quest_button.pressed.connect(_on_quest_button_pressed.bind(curr_quest))
			quest_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
			quest_button.set_size(Vector2(QUESTS_WIDTH, QUESTS_HEIGHT))
			quest_button.set_position(Vector2(0, QUESTS_MARGIN + curr_quest * (QUESTS_HEIGHT + QUESTS_MARGIN)))
			quests_control.add_child(quest_button)
			curr_quest += 1
	
	var rq = RadiantQuestManager.get_active_quest()
	if not rq.is_empty():
		var radiant_quest_button = Button.new()
		radiant_quest_button.add_theme_color_override("font_color", Color(0, 0, 0))
		radiant_quest_button.add_theme_font_size_override("font_size", 30)
		var rq_title = rq.title + (" (Accomplished)" if rq.state == "Accomplished" else "")
		radiant_quest_button.set_text(rq_title)
		radiant_quest_button.pressed.connect(_on_quest_button_pressed.bind(curr_quest))
		radiant_quest_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
		radiant_quest_button.set_size(Vector2(QUESTS_WIDTH, QUESTS_HEIGHT))
		radiant_quest_button.set_position(Vector2(0, QUESTS_MARGIN + curr_quest * (QUESTS_HEIGHT + QUESTS_MARGIN)))
		quests_control.add_child(radiant_quest_button)
		curr_quest += 1

func _on_quest_button_pressed(index: int) :
	if index == quests_info.size() :
		# Radiant Quest
		var rq = RadiantQuestManager.get_active_quest()
		if not rq.is_empty():
			displayed_quest_title.set_text(rq.title)
			displayed_quest_description.set_text(rq.description)
			if index != curr_quest :
				displayed_quest.visible = true
			else :
				displayed_quest.visible = not displayed_quest.visible
			curr_quest = index
			return
	
	var quest_info = quests_info[index]
	displayed_quest_title.set_text(quest_info.name)
	displayed_quest_description.set_text(
		"Difficulty: {difficulty}
		Location: {location}
		Description: {description}
		Reward: {reward}".format({"difficulty" : quest_info.difficulty, "location" : quest_info.location, 
		"description": quest_info.description, "reward": quest_info.reward}))
	if index != curr_quest :
		displayed_quest.visible = true
	else :
		displayed_quest.visible = not displayed_quest.visible
	curr_quest = index
		
