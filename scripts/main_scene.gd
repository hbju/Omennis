extends Node2D

@onready var combat_scene: CombatMap = $combat_scene
@onready var overworld = $overworld


# Called when the node enters the scene tree for the first time.
func _ready():
	combat_scene.visible = false
	overworld.visible = true
	overworld.toggle_ui(true)

	overworld.event_manager.fight_ui.launch_fight.connect(lauch_combat)
	combat_scene.combat_ended.connect(_end_combat)


func lauch_combat(party: Array[Character], enemies: EnemyGroup): 
	combat_scene.visible = true
	overworld.visible = false
	overworld.toggle_ui(false)
	overworld.player.toggle_camera()

	combat_scene.enter_combat(party, enemies.enemies)


func _end_combat(result: bool):
	combat_scene.visible = false
	overworld.visible = true
	overworld.toggle_ui(true)
	overworld.player.toggle_camera()

	overworld.event_manager.exit_fight(result)



