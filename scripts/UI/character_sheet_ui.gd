# CharacterSheetUI.gd
extends Control

@export var debugging: bool = false

# --- Signals ---
signal character_sheet_closed
signal non_combat_stat_increased(stat_name: String)

# --- References ---
# Header
@onready var title: Label = $background/borders/header/title_label
@onready var large_portrait: TextureRect = $background/sheet_hbox/portrait/avatar_portrait
@onready var class_icon    : TextureRect = $background/sheet_hbox/right_part/class_badge/class_icon

# Tab Buttons
@onready var stats_tab_button        : TextureButton = $background/sheet_hbox/sheet_vbox/tab_buttons_box/stats_tab_button
@onready var traits_tab_button       : TextureButton = $background/sheet_hbox/sheet_vbox/tab_buttons_box/traits_tab_button
@onready var skills_tab_button       : TextureButton = $background/sheet_hbox/sheet_vbox/tab_buttons_box/skills_tab_button
@onready var relationships_tab_button: TextureButton = $background/sheet_hbox/sheet_vbox/tab_buttons_box/relationships_tab_button

# Tab Content Panels
@onready var stats_panel        : Control = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel
@onready var traits_panel       : Control = $background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel
@onready var skills_panel       : Control = $background/sheet_hbox/sheet_vbox/tab_content_container/skills_panel
@onready var relationships_panel: Control = $background/sheet_hbox/sheet_vbox/tab_content_container/relationships_panel

# Stats Panel Content
@onready var stats_label:            Label = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/overview_label
@onready var perception_value_label: Label = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/perception_hbox/stat_value
@onready var increase_perception_button: TextureButton = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/perception_hbox/stat_increase
@onready var charisma_value_label:   Label = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/charisma_hbox/stat_value
@onready var increase_charisma_button:   TextureButton = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/charisma_hbox/stat_increase
@onready var lore_value_label:       Label = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/lore_hbox/stat_value
@onready var increase_lore_button:       TextureButton = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/lore_hbox/stat_increase
@onready var survival_value_label:   Label = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/survival_hbox/stat_value
@onready var increase_survival_button:   TextureButton = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/survival_hbox/stat_increase
@onready var logistics_value_label:  Label = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/logistics_hbox/stat_value
@onready var increase_logistics_button:  TextureButton = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats_vbox/logistics_hbox/stat_increase
@onready var unspent_points_label:   Label = $background/sheet_hbox/sheet_vbox/tab_content_container/stats_panel/stats_vbox/non_combat_stats

# Traits Panel Content (Example for Valor)
@onready var valor_bar: Array[ProgressBar] = [
	$background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel/traits_vbox/valor_vbox/progress_hbox/left_side_trait,
	$background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel/traits_vbox/valor_vbox/progress_hbox/right_side_trait
]
@onready var temper_bar: Array[ProgressBar] = [
	$background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel/traits_vbox/temper_vbox/progress_hbox/left_side_trait,
	$background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel/traits_vbox/temper_vbox/progress_hbox/right_side_trait
]
@onready var ethics_bar: Array[ProgressBar] = [
	$background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel/traits_vbox/ethics_vbox/progress_hbox/left_side_trait,
	$background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel/traits_vbox/ethics_vbox/progress_hbox/right_side_trait
]
@onready var worldview_bar: Array[ProgressBar] = [
	$background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel/traits_vbox/worldview_vbox/progress_hbox/left_side_trait,
	$background/sheet_hbox/sheet_vbox/tab_content_container/traits_panel/traits_vbox/worldview_vbox/progress_hbox/right_side_trait
]

# Skills Panel Content
@onready var skill_ui: SkillUI = $background/sheet_hbox/sheet_vbox/tab_content_container/skills_panel/skill_vbox/skill_ui

# Relationship Panel Content
const RelationshipEntryScene = preload("res://scenes/relationship_entry.tscn")
@onready var relationship_list_vbox: VBoxContainer = $background/sheet_hbox/sheet_vbox/tab_content_container/relationships_panel/ScrollContainer/relationships_vbox

@onready var close_button: TextureButton = $background/sheet_hbox/right_part/close_button

var current_party_member: PartyMember = null
var active_panel: Control = null

func _ready():
	stats_tab_button.pressed.connect(_on_tab_button_pressed.bind(stats_panel, stats_tab_button))
	traits_tab_button.pressed.connect(_on_tab_button_pressed.bind(traits_panel, traits_tab_button))
	skills_tab_button.pressed.connect(_on_tab_button_pressed.bind(skills_panel, skills_tab_button))
	relationships_tab_button.pressed.connect(_on_tab_button_pressed.bind(relationships_panel, relationships_tab_button))

	close_button.pressed.connect(_on_close_button_pressed)

	# Connect '+' button signals for non-combat stats
	increase_perception_button.pressed.connect(_on_increase_stat_pressed.bind("Perception"))
	increase_charisma_button.pressed.connect(_on_increase_stat_pressed.bind("Charisma"))
	increase_lore_button.pressed.connect(_on_increase_stat_pressed.bind("Lore"))
	increase_survival_button.pressed.connect(_on_increase_stat_pressed.bind("Survival"))
	increase_logistics_button.pressed.connect(_on_increase_stat_pressed.bind("Logistics"))

	if debugging : 
		var character = PartyMember.new_rand()
		character.receive_experience(10000)
		show_sheet(character)
	else :
		hide() # Start hidden

func _on_tab_button_pressed(panel_to_show: Control, button_pressed: TextureButton):
	if active_panel:
		active_panel.hide()

	panel_to_show.show()
	active_panel = panel_to_show

	button_pressed.disabled = true
	for button in [stats_tab_button, traits_tab_button, skills_tab_button, relationships_tab_button]:
		if button != button_pressed:
			button.disabled = false

func _on_close_button_pressed():
	hide()
	character_sheet_closed.emit() 

func show_sheet(party_member: PartyMember):
	current_party_member = party_member
	if not current_party_member:
		printerr("CharacterSheetUI: No party member data to display!")
		hide()
		return

	title.text = current_party_member.character_name

	# Update header
	if large_portrait: large_portrait.texture = load(current_party_member.get_portrait_path())
	if class_icon: class_icon.texture = load("res://assets/ui/classes_icons/" + current_party_member.get_char_class().to_lower() + ".png")

	# Populate all tabs
	_update_stats_panel()
	_update_traits_panel()
	_update_skills_panel()
	_update_relationships_panel() 

	# Default to showing the stats tab
	_on_tab_button_pressed(stats_panel, stats_tab_button)
	show()

func _update_stats_panel():
	if not current_party_member or not stats_panel: return # Check if panel is active or tree ready

	# Update HP/Damage labels (if you have them here)
	stats_label.text = "Lvl : %d\nXP : %d/%d\nSkill Points : %d\nMax HP : %d\nBase Damage : %d" % [ 
		current_party_member.character_level,
		current_party_member.character_experience,
		current_party_member.next_level(),
		current_party_member.skill_points,
		current_party_member.max_health,
		current_party_member.base_damage
	]

	# Update Non-Combat Stats
	perception_value_label.text = str(current_party_member.non_combat_stats.Perception)
	charisma_value_label.text = str(current_party_member.non_combat_stats.Charisma)
	lore_value_label.text = str(current_party_member.non_combat_stats.Lore)
	survival_value_label.text = str(current_party_member.non_combat_stats.Survival)
	logistics_value_label.text = str(current_party_member.non_combat_stats.Logistics)	

	unspent_points_label.text = "Non-Combat Stats (Available points : %d) :" % current_party_member.unspent_non_combat_stat_points

	# Enable/disable '+' buttons
	var can_spend = current_party_member.unspent_non_combat_stat_points > 0
	increase_perception_button.disabled = not can_spend
	increase_perception_button.modulate = Color(1, 1, 1, 1) if can_spend else Color(0.3, 0.3, 0.3, 1)
	increase_charisma_button.disabled = not can_spend
	increase_charisma_button.modulate = Color(1, 1, 1, 1) if can_spend else Color(0.3, 0.3, 0.3, 1)
	increase_lore_button.disabled = not can_spend
	increase_lore_button.modulate = Color(1, 1, 1, 1) if can_spend else Color(0.3, 0.3, 0.3, 1)
	increase_survival_button.disabled = not can_spend
	increase_survival_button.modulate = Color(1, 1, 1, 1) if can_spend else Color(0.3, 0.3, 0.3, 1)
	increase_logistics_button.disabled = not can_spend
	increase_logistics_button.modulate = Color(1, 1, 1, 1) if can_spend else Color(0.3, 0.3, 0.3, 1)

func _update_traits_panel():
	if not current_party_member or not traits_panel: return

	# Valor
	var valor_score = current_party_member.personality_traits.Valor
	if valor_score > 0:
		valor_bar[0].value = 0
		valor_bar[1].value = valor_score
	else:
		valor_bar[0].value = -valor_score
		valor_bar[1].value = 0
	
	# Temper
	var temper_score = current_party_member.personality_traits.Temper
	if temper_score > 0:
		temper_bar[0].value = 0
		temper_bar[1].value = temper_score
	else:
		temper_bar[0].value = -temper_score
		temper_bar[1].value = 0

	# Ethics
	var ethics_score = current_party_member.personality_traits.Ethics
	if ethics_score > 0:
		ethics_bar[0].value = 0
		ethics_bar[1].value = ethics_score
	else:
		ethics_bar[0].value = -ethics_score
		ethics_bar[1].value = 0

	# Worldview
	var worldview_score = current_party_member.personality_traits.Worldview
	if worldview_score > 0:
		worldview_bar[0].value = 0
		worldview_bar[1].value = worldview_score
	else:
		worldview_bar[0].value = -worldview_score
		worldview_bar[1].value = 0

func _update_skills_panel():
	if not current_party_member or not skills_panel: return
	if skill_ui:
		skill_ui.update_ui(current_party_member)

func _update_relationships_panel():
	if not current_party_member or not relationship_list_vbox: return

	for child in relationship_list_vbox.get_children(): child.queue_free()

	  # Iterate through ALL party members in GameState to find others
	for other_member in GameState.party: # Assuming game_state is accessible
		if other_member.character_unique_id == current_party_member.character_unique_id:
			continue

		var entry_instance = RelationshipEntryScene.instantiate()
		entry_instance.get_node("relation_hbox/other_char_avatar/avatar_portrait").texture = load(other_member.get_portrait_path()) 
		entry_instance.get_node("relation_hbox/char_label").text = other_member.character_name + "\n" + current_party_member.get_derived_relationship_name(other_member)
		  
		var r_tracks = current_party_member.relationships.get(other_member.character_unique_id, {})
		var friendship = r_tracks.get(PartyMember.RELATIONSHIP_TRACK.FRIENDSHIP, 50)
		var respect = r_tracks.get(PartyMember.RELATIONSHIP_TRACK.RESPECT, 50)
		var trust = r_tracks.get(PartyMember.RELATIONSHIP_TRACK.TRUST, 50)
		var rivalry = r_tracks.get(PartyMember.RELATIONSHIP_TRACK.RIVALRY, 0)
		var attraction = r_tracks.get(PartyMember.RELATIONSHIP_TRACK.ATTRACTION, 0)
		var fear = r_tracks.get(PartyMember.RELATIONSHIP_TRACK.FEAR, 0)

		if friendship > 0:
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/friendship_vbox/progress_hbox/left_side_rel").value = 0
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/friendship_vbox/progress_hbox/right_side_rel").value = friendship - 50
		else:
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/friendship_vbox/progress_hbox/left_side_rel").value = 50-friendship
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/friendship_vbox/progress_hbox/right_side_rel").value = 0
		if respect > 0:
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/respect_vbox/progress_hbox/left_side_rel").value = 0
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/respect_vbox/progress_hbox/right_side_rel").value = respect - 50
		else:
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/respect_vbox/progress_hbox/left_side_rel").value = 50 - respect
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/respect_vbox/progress_hbox/right_side_rel").value = 0
		if trust > 0:
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/trust_vbox/progress_hbox/left_side_rel").value = 0
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/trust_vbox/progress_hbox/right_side_rel").value = trust - 50
		else:
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/trust_vbox/progress_hbox/left_side_rel").value = 50 - trust
			entry_instance.get_node("relation_hbox/relation_tracks_vbox/trust_vbox/progress_hbox/right_side_rel").value = 0
		entry_instance.get_node("relation_hbox/relation_tracks_vbox/rivalry_vbox/progress_hbox/right_side_rel").value = rivalry
		entry_instance.get_node("relation_hbox/relation_tracks_vbox/attraction_vbox/progress_hbox/right_side_rel").value = attraction
		entry_instance.get_node("relation_hbox/relation_tracks_vbox/fear_vbox/progress_hbox/right_side_rel").value = fear

		relationship_list_vbox.add_child(entry_instance)

func _on_increase_stat_pressed(stat_name: String):
	if current_party_member and current_party_member.spend_non_combat_stat_point(stat_name):
		AudioManager.play_sfx(AudioManager.UI_BUTTON_CLICK) 
		_update_stats_panel() 
		non_combat_stat_increased.emit(stat_name)