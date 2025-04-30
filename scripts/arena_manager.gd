# ArenaManager.gd
extends Node # Or Control/Node2D depending on your root

@onready var combat_scene: CombatMap = $combat_scene
@onready var skill_ui: SkillUI = $skill_ui
# Add later: @onready var progression_screen: Control = $ProgressionScreen

var current_wave: int = 0
var player_character: PartyMember = null # The single character for the arena
var is_in_combat: bool = false
var is_in_progression: bool = false # To manage UI state

func _ready():
    # Hide elements initially
    combat_scene.visible = false
    combat_scene.toggle_ui(false) # Ensure combat UI is off
    skill_ui.visible = false

    # Connect combat end signal
    combat_scene.combat_ended.connect(_on_combat_ended)

    # Start the arena when ready
    call_deferred("start_arena") # Use call_deferred ensure everything is ready

func start_arena():
    print("Starting Endless Arena!")
    current_wave = 0
    # --- Character Creation/Selection (Simple V1) ---
    # For now, create a default Level 1 Warrior
    # TODO: Add character selection later
    player_character = PartyMember.new("Arena Champion", Character.CLASSES.Warrior, 0, 1, PartyMember.SEX.Male)
    # Give some starting skills? Or let player pick first? Let's give default for now.
    player_character.skill_list = [Charge.new()] # Example starting skills
    print("Player Character Created: ", player_character.character_name)

    # Start the first wave
    _prepare_next_wave()

func _prepare_next_wave():
    is_in_combat = false
    is_in_progression = false
    current_wave += 1
    print("--- Preparing Wave %d ---" % current_wave)

    # 1. Hide Progression/Skill UI (if they were visible)
    skill_ui.visible = false
    # progression_screen.hide() # Add later

    # 2. Generate Enemies for the wave
    var enemies_for_wave: Array[Character] = _generate_enemies(current_wave)
    if enemies_for_wave.is_empty():
        printerr("Failed to generate enemies for wave ", current_wave)
        _game_over("Error") # Or handle differently
        return

    # 3. Configure Combat Map (Layout, Obstacles - Placeholder for now)
    _configure_combat_map()

    # 4. Start Combat
    print("Starting combat for Wave ", current_wave)
    is_in_combat = true
    combat_scene.visible = true
    combat_scene.toggle_ui(true) # Turn combat UI on
    # Ensure player character data is up-to-date before combat
    # Need a way to pass the single player and enemies to combat_scene
    combat_scene.setup_arena_combat(player_character, enemies_for_wave) # NEW function needed in CombatMap

func _generate_enemies(wave_num: int) -> Array[Character]:
    print("Generating enemies for wave ", wave_num)
    var enemies: Array[Character] = []
    # --- Enemy Generation Logic ---
    # Simple V1: Increase count and level slightly each wave
    var enemy_count = 1 + floori(wave_num / 2.0)
    var enemy_level = 1 + floori(wave_num / 3.0)
    var enemy_base_hp = 80 + wave_num * 10
    var enemy_base_damage = 8 + wave_num * 2

    print("Wave %d: %d enemies, Level %d" % [wave_num, enemy_count, enemy_level])

    var possible_classes = [Character.CLASSES.Warrior, Character.CLASSES.Mage, Character.CLASSES.Rogue]
    # TODO: Expand enemy variety, add skills based on wave
    var available_skills = {
         Character.CLASSES.Warrior: [Charge.new(), ShieldBash.new()],
         Character.CLASSES.Mage: [FiresparkMage.new(), Frostbolt.new()],
         Character.CLASSES.Rogue: [Sprint.new()] # Add basic rogue skills later
    }


    for i in range(enemy_count):
        var chosen_class = possible_classes[randi() % possible_classes.size()]
        var portrait_idx = randi() % 10 # Use first 10 monster portraits
        var enemy_name = Character.CLASSES.keys()[chosen_class] + " Grunt " + str(i+1)

        var new_enemy = Character.new(enemy_name, chosen_class, portrait_idx, enemy_level)

        # --- Assign Skills to Enemy (Simple V1) ---
        if available_skills.has(chosen_class):
            # Give one random skill from the basic pool for their class
             var skill_pool = available_skills[chosen_class]
             if not skill_pool.is_empty():
                  new_enemy.skill_list.append(skill_pool[randi() % skill_pool.size()])

        # TODO: Set HP/Damage based on scaling
        # Need to access these properties - Character doesn't have them directly.
        # We might need an EnemyCombatStats component or add them to Character?
        # For now, AICombatCharacter will use its defaults.

        enemies.append(new_enemy)

    return enemies


func _configure_combat_map():
    # Placeholder: Later, load different layouts or place obstacles
    print("Configuring combat map layout (Placeholder)")
    # combat_scene.load_layout(current_wave % 3) # Example

func _on_combat_ended(victory: bool):
    if not is_in_combat: return # Prevent double calls

    print("Combat Ended! Victory: ", victory)
    is_in_combat = false
    combat_scene.visible = false
    combat_scene.toggle_ui() # Turn combat UI off

    if victory:
        # Go to Progression Phase
        _show_progression_screen()
    else:
        # Game Over
        _game_over("Defeated")

func _show_progression_screen():
    is_in_progression = true
    print("Showing Progression Screen for Wave ", current_wave)

    # 1. Calculate XP
    # Simple V1: Fixed XP per wave + bonus
    var xp_reward = 500 + current_wave * 150
    xp_reward = roundi(xp_reward * randf_range(0.9, 1.1))
    print("XP Reward: ", xp_reward)

    # 2. Get state BEFORE applying XP
    var char_before = player_character.copy() # Use the copy method!

    # 3. Apply XP (Directly modify the character instance for arena)
    player_character.receive_experience(xp_reward)
    print("Applied XP. Level: %d, XP: %d/%d, Points: %d" % [
         player_character.character_level, player_character.character_experience,
         player_character.next_level(), player_character.skill_points
    ])

    # 4. Show Progression UI (Implement this scene in next phase)
    # progression_screen.setup(char_before, player_character, xp_reward)
    # progression_screen.show()
    # --- TEMPORARY V1 ---
    # For now, just print and allow skill check immediately if needed
    if player_character.skill_points > 0:
        print("Skill points available! Opening Skill UI...")
        skill_ui.update_ui(player_character)
        skill_ui.visible = true
        # Need a button in SkillUI to confirm skill choices and proceed
        # Add a "Confirm Skills & Continue" button to SkillUI?
    else:
         # No skill points, proceed to next wave directly after short delay? Or button?
         print("No skill points. Proceeding to next wave shortly...")
         # Use a Timer or a simple "Proceed" button on a minimal screen
         call_deferred("_prepare_next_wave") # Auto-proceed for now


# Called when player confirms progression/skill choices
func _on_progression_continue_pressed(): # Connect this signal from ProgressionScreen/SkillUI later
     if not is_in_progression: return
     print("Progression confirmed.")
     is_in_progression = false
     skill_ui.visible = false # Hide skill UI if it was open
     # progression_screen.hide()
     _prepare_next_wave()


func _game_over(reason: String):
    print("--- GAME OVER ---")
    print("Reason: ", reason)
    print("Reached Wave: ", current_wave)
    # TODO: Show a game over screen with score
    # TODO: Add button to return to main menu
    get_tree().quit() # Simple exit for now