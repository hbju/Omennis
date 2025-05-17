extends Node2D

@onready var combat_scene: CombatMap = $combat_scene
@onready var overworld: Overworld = $overworld

const PostFightScreenScene = preload("res://scenes/post_fight_screen.tscn")
var post_fight_screen_instance: Control = null

var curr_victory: bool = false

var XP_PER_ENEMY_LEVEL = 250

# Called when the node enters the scene tree for the first time.
func _ready():
	combat_scene.visible = false
	combat_scene.toggle_ui(false)
	overworld.visible = true
	overworld.toggle_ui(true)

	overworld.event_manager.fight_ui.launch_fight.connect(lauch_combat)
	overworld.event_manager.fight_ui.resolve_fight.connect(_end_combat)
	combat_scene.combat_ended.connect(_end_combat)

	AudioManager.play_music(AudioManager.OVERWORLD_MUSIC[0]) # Play overworld music


func lauch_combat(party: Array[PartyMember], enemies: EnemyGroup):
	combat_scene.visible = true
	combat_scene.toggle_ui(true)
	overworld.visible = false
	overworld.toggle_ui(false)
	overworld.player.toggle_camera(false)
	overworld.disable_collisions(true)

	combat_scene.enter_combat(party, enemies.enemies)
	AudioManager.play_music(AudioManager.BATTLE_MUSIC, true) 


func _end_combat(victory: bool):	
	curr_victory = victory

	combat_scene.visible = false
	combat_scene.toggle_ui(false)
	overworld.visible = true

	overworld.toggle_ui(true)
	overworld.player.toggle_camera(true)
	overworld.disable_collisions(false)

	var last_enemy_group: EnemyGroup = overworld.event_manager.fight_ui.enemy_group

	var xp_reward = 0
	if last_enemy_group:
		for enemy_char in last_enemy_group.enemies:
			# Base XP per enemy level, modify as needed
			xp_reward += enemy_char.character_level * XP_PER_ENEMY_LEVEL
		if not victory:
			xp_reward *= 0.3 # Penalty for losing (or set to 0?)
	else:
		printerr("Cannot calculate XP, last_enemy_group is null!")


	var party_before: Array[PartyMember] = []
	for member in GameState.party:
		party_before.append(member.duplicate())

	if xp_reward > 0:
		GameState.receive_experience(xp_reward)

	if PostFightScreenScene:
		if post_fight_screen_instance == null or not is_instance_valid(post_fight_screen_instance):
			post_fight_screen_instance = PostFightScreenScene.instantiate()
			overworld.get_node("UI").add_child(post_fight_screen_instance) # Add to main scene tree
			post_fight_screen_instance.get_node("background/proceed_button").pressed.connect(_on_post_fight_proceed) # Connect button

		# Pass data to the screen's script (needs a function like setup())
		AudioManager.play_music(AudioManager.VICTORY_STINGER if victory else AudioManager.DEFEAT_STINGER)
		post_fight_screen_instance.setup(party_before, GameState.party, xp_reward, victory)
		post_fight_screen_instance.show()
	else:
		printerr("PostFightScreenScene not loaded!")
		# If screen fails, proceed directly
		_on_post_fight_proceed()

func _on_post_fight_proceed():
	AudioManager.play_music(AudioManager.OVERWORLD_MUSIC[0]) # Resume overworld music

	if post_fight_screen_instance and is_instance_valid(post_fight_screen_instance):
		post_fight_screen_instance.hide()

	overworld.event_manager.exit_fight(curr_victory)



