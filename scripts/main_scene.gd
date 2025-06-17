extends Node2D

@onready var combat_scene: CombatMap = $combat_scene
@onready var overworld: Overworld = $overworld

@onready var post_fight_screen_instance: Control = $overworld/UI/post_fight_screen

var curr_victory: bool = false

var XP_PER_ENEMY_LEVEL = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	combat_scene.visible = false
	combat_scene.toggle_ui(false)
	overworld.visible = true
	overworld.toggle_ui(true)

	overworld.event_manager.fight_ui.launch_fight.connect(lauch_combat)
	overworld.event_manager.fight_ui.resolve_fight.connect(_end_combat)

	
	post_fight_screen_instance.get_node("background/proceed_button").pressed.connect(_on_post_fight_proceed) # Connect button

	combat_scene.combat_ended.connect(_end_combat)

	AudioManager.play_music(AudioManager.OVERWORLD_MUSIC[0]) # Play overworld music


func lauch_combat(party: Array[PartyMember], enemies: Array[EnemyGroup]):
	combat_scene.visible = true
	combat_scene.toggle_ui(true)
	overworld.visible = false
	overworld.toggle_ui(false)
	overworld.player.toggle_camera(false)
	overworld.disable_collisions(true)

	var all_enemies: Array[Character] = []
	for enemy_group in enemies:
		for enemy_char in enemy_group.enemies:
			all_enemies.append(enemy_char)


	combat_scene.enter_combat(party, all_enemies)
	AudioManager.play_music(AudioManager.BATTLE_MUSIC, true) 


func _end_combat(victory: bool):	
	curr_victory = victory

	combat_scene.visible = false
	combat_scene.toggle_ui(false)
	overworld.visible = true

	overworld.toggle_ui(true)
	overworld.player.toggle_camera(true)
	overworld.disable_collisions(false)

	var last_enemy_groups: Array[EnemyGroup] = overworld.event_manager.fight_ui.all_enemies

	var xp_reward = 50
	if last_enemy_groups:
		for enemy_group in last_enemy_groups:
			for enemy_char in enemy_group.enemies:
			# Base XP per enemy level, modify as needed
				xp_reward += enemy_char.character_level * XP_PER_ENEMY_LEVEL
		if not victory:
			xp_reward *= 0.3 # Penalty for losing (or set to 0?)
	else:
		printerr("Cannot calculate XP, last_enemy_groups is null!")


	var party_before: Array[PartyMember] = []
	for member in GameState.party:
		party_before.append(member.duplicate())

	
	var received_xp = []
	if xp_reward > 0:
		received_xp = GameState.receive_experience(xp_reward)
	else:
		for member in GameState.party:
			received_xp.append(0)
		
	# Pass data to the screen's script (needs a function like setup())
	AudioManager.play_music(AudioManager.VICTORY_STINGER if victory else AudioManager.DEFEAT_STINGER)
	post_fight_screen_instance.setup(party_before, GameState.party, received_xp, victory)
	post_fight_screen_instance.show()


func _on_post_fight_proceed():
	AudioManager.play_music(AudioManager.OVERWORLD_MUSIC[0]) # Resume overworld music

	if post_fight_screen_instance and is_instance_valid(post_fight_screen_instance):
		post_fight_screen_instance.hide()

	overworld.event_manager.exit_fight(curr_victory)



