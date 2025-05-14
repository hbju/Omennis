# ArenaManager.gd
extends Node # Or Control/Node2D depending on your root

@onready var combat_scene: CombatMap = $combat_scene
@onready var skill_ui: SkillUI = $skill_ui
@onready var progression_screen: Control = $arena_progression_screen
@onready var class_selection_screen: Control = $arena_class_selection
@onready var game_over_screen: Control = $game_over_screen

var current_wave: int = 0
var player_character: PartyMember = null # The single character for the arena
var is_in_combat: bool = false
var is_in_progression: bool = false # To manage UI state

func _ready():
	# Hide elements initially
	combat_scene.visible = false
	combat_scene.toggle_ui(false) # Ensure combat UI is off
	skill_ui.visible = false
	skill_ui.skills_confirmed.connect(_on_progression_continue_pressed)

	class_selection_screen.class_selected.connect(_on_arena_class_chosen)

	progression_screen.view_skills_pressed.connect(_on_view_skills_pressed)
	progression_screen.next_wave_pressed.connect(_on_progression_continue_pressed)

	game_over_screen.retry_arena_pressed.connect(_on_retry_arena)
	game_over_screen.main_menu_pressed.connect(_on_return_to_main_menu)
	
	# Connect combat end signal
	combat_scene.combat_ended.connect(_on_combat_ended)

	# Start the arena when ready
	call_deferred("show_class_selection") # Use call_deferred ensure everything is ready

func show_class_selection():
	combat_scene.visible = false
	combat_scene.toggle_ui(false)
	skill_ui.visible = false
	progression_screen.hide()

	class_selection_screen.prompt_class_selection()

func _prepare_next_wave():
	is_in_combat = false
	is_in_progression = false
	current_wave += 1
	print("--- Preparing Wave %d ---" % current_wave)

	# 1. Hide Progression/Skill UI (if they were visible)
	skill_ui.visible = false
	progression_screen.hide() # Add later

	# 2. Generate Enemies for the wave
	var enemies_for_wave: Array[Character] = _generate_enemies(current_wave)
	if enemies_for_wave.is_empty():
		printerr("Failed to generate enemies for wave ", current_wave)
		_game_over() # Or handle differently
		return

	# 3. Configure Combat Map (Layout, Obstacles - Placeholder for now)
	_configure_combat_map()

	# 4. Start Combat
	print("Starting combat for Wave ", current_wave)
	AudioManager.play_music(AudioManager.BATTLE_MUSIC, true) # Play battle music
	is_in_combat = true
	combat_scene.visible = true
	combat_scene.toggle_ui(true) # Turn combat UI on
	combat_scene.enter_combat([player_character], enemies_for_wave) # NEW function needed in CombatMap

func _generate_enemies(wave_num: int) -> Array[Character]:
	print("Generating enemies for wave ", wave_num)
	var enemies: Array[Character] = []
	# --- Enemy Generation Logic ---
	# Simple V1: Increase count and level slightly each wave
	var enemy_count = 1 + floori(wave_num / 3.0)
	var enemy_level = 1 + floori(wave_num / 3.0)

	print("Wave %d: %d enemies, Level %d" % [wave_num, enemy_count, enemy_level])

	var class_keys = EnemyData.ENEMY_CLASS_DEFINITIONS.keys()

	for i in range(enemy_count):
		var chosen_class_key = class_keys[randi() % class_keys.size()]
		var class_data = EnemyData.ENEMY_CLASS_DEFINITIONS[chosen_class_key]

		var enemy_actual_level = max(1, enemy_level + randi_range(-1, 1)) # +/- 1 level variance

		var max_hp = class_data.base_hp + (enemy_actual_level - 1) * class_data.hp_per_level
		var damage_stat = class_data.base_damage_stat + (enemy_actual_level - 1) * class_data.damage_stat_per_level

		var portrait_idx = class_data.portraits[randi() % class_data.portraits.size()]
		var enemy_name = chosen_class_key + " Mk." + str(enemy_actual_level) # Simple name

		var new_char_def = Character.new(
			enemy_name,
			class_data.class_enum, 
			portrait_idx,
			enemy_actual_level,
			max_hp,
			damage_stat,
		)

		for skill_entry in class_data.skill_pool_config:
			if enemy_actual_level >= skill_entry.min_level:
				new_char_def.skill_list.append(skill_entry.skill.new())

		enemies.append(new_char_def) # Add the Character definition

	return enemies


func _configure_combat_map():
	# Placeholder: Later, load different layouts or place obstacles
	print("Configuring combat map layout (Placeholder)")
	# combat_scene.load_layout(current_wave % 3) # Example

func _on_arena_class_chosen(selected_class_enum: Character.CLASSES):
	print("ArenaManager: Class chosen - ", Character.CLASSES.keys()[selected_class_enum])
	current_wave = 0 # Reset wave count for a new run

	var sex = PartyMember.SEX.Male if randi() % 2 == 0 else PartyMember.SEX.Female
	var portrait_idx = randi() % (PartyMember.NB_MALE_PORTRAIT if sex == PartyMember.SEX.Male else PartyMember.NB_FEMALE_PORTRAIT)

	player_character = PartyMember.new(
		"Arena Champion",
		selected_class_enum,
		portrait_idx, # Example random portrait
		1,            # Start at level 1
		sex           # Example random sex
	)

	print("Player Character Created: ", player_character.character_name, " as ", player_character.get_char_class())

	# Proceed to the first wave
	_prepare_next_wave() # This will show combat scene, etc.


func _on_combat_ended(victory: bool):
	if not is_in_combat: return # Prevent double calls

	AudioManager.play_music(AudioManager.VICTORY_STINGER if victory else AudioManager.DEFEAT_STINGER)

	print("Combat Ended! Victory: ", victory)
	is_in_combat = false
	# combat_scene.visible = false
	combat_scene.character_tooltip_instance.hide() # Hide character tooltip
	combat_scene.toggle_ui(false) # Turn combat UI off

	if victory:
		# Go to Progression Phase
		_show_progression_screen()
	else :
		# Game Over
		_game_over()

func _show_progression_screen():
	is_in_progression = true
	print("Showing Progression Screen for Wave ", current_wave)

	# 1. Calculate XP
	# Simple V1: Fixed XP per wave + bonus
	var xp_reward = 1000 + current_wave **2 * 50
	xp_reward = roundi(xp_reward * randf_range(0.9, 1.1))
	print("XP Reward: ", xp_reward)

	# 2. Get state BEFORE applying XP
	var char_before = player_character.duplicate() # Use the copy method!

	# 3. Apply XP (Directly modify the character instance for arena)
	player_character.receive_experience(xp_reward)

	# 4. Show Progression UI (Implement this scene in next phase)
	progression_screen.setup(char_before, player_character, xp_reward)
	progression_screen.show()


# Called when player confirms progression/skill choices
func _on_progression_continue_pressed(): # Connect this signal from ProgressionScreen/SkillUI later
	if not is_in_progression: return

	is_in_progression = false
	skill_ui.visible = false
	progression_screen.hide()
	_prepare_next_wave()

func _on_view_skills_pressed():
	if not is_in_progression: return

	progression_screen.hide() # Hide progression screen
	skill_ui.update_ui(player_character) # Update skill UI with current char
	skill_ui.visible = true # Show skill UI

func _on_retry_arena():
	show_class_selection() # Go back to class selection for a fresh start

func _on_return_to_main_menu():
	var err = get_tree().change_scene_to_file("res://scenes/main_menu.tscn") # Adjust path
	if err != OK:
		printerr("Error changing scene to Main Menu: ", err)

func _game_over():
	is_in_combat = false # Ensure flags are reset
	is_in_progression = false
	combat_scene.visible = false
	if combat_scene.has_method("toggle_ui"): combat_scene.toggle_ui(false)
	if skill_ui: skill_ui.visible = false
	if progression_screen and progression_screen.is_visible_in_tree(): progression_screen.hide()

	game_over_screen.show_screen(current_wave, player_character)