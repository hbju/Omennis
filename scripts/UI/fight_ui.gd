@tool
extends Control
class_name FightUI

@onready var party_display = $bg/party_display
@onready var enemies_display: VBoxContainer = $bg/enemies_display
@onready var chances_label = $bg/chances_bg/chances_label
@onready var result_label = $bg/result_label
@onready var fight_button = $bg/fight_button
@onready var simulation_button = $bg/simulation_button
@onready var flee_button = $bg/flee_button
@onready var proceed_button = $bg/proceed_button

@onready var background: TextureRect = $bg
@onready var character_sheet_ui: Control = $character_sheet_ui

@export var debug_fight = false : 
	set(value) : 
		_debug_fight()

signal launch_fight(party: Array[PartyMember], enemies: Array[EnemyGroup])
signal resolve_fight(fight_ccl: String)

var fight_result = false

var party: Array[PartyMember]
var enemy_group_scene = preload("res://scenes/fight_ui_enemy_group.tscn")
var all_enemies: Array[EnemyGroup]

var party_strength: float
var enemy_strength: float

func _ready() : 
	if Engine.is_editor_hint() :
		enemies_display.enemy_group_changed.connect(_debug_fight)
		for char_display in party_display.get_children() : 
			char_display = char_display as CharacterDisplay
			char_display.character_changed.connect(_debug_fight)

	proceed_button.pressed.connect(_on_proceed_button_pressed)
	proceed_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	fight_button.pressed.connect(_on_fight_button_pressed)
	fight_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_ENTER_COMBAT))
	simulation_button.pressed.connect(_on_simulate_button_pressed)
	simulation_button.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	for i in range(0, 4) :
		var display: CharacterDisplay = party_display.get_child(i) as CharacterDisplay
		display.show_skill_tree.connect(_on_show_skill_tree.bind(i))
		display.show_skill_tree.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))

	character_sheet_ui.character_sheet_closed.connect(background.show)
	
	
func update_ui(_party: Array[PartyMember], enemies: Array[EnemyGroup]) :
	background.show()
	character_sheet_ui.hide()

	self.party = _party
	self.all_enemies = enemies
	
	var displays = party_display.get_children()
	for i in range(0, _party.size()):
		var display: CharacterDisplay = displays[i]
		display.update_character(_party[i])
		display.visible = true
		display.show_delete_button = false
	for i in range(_party.size(), 4) :
		displays[i].visible = false

	for child in enemies_display.get_children():
		enemies_display.remove_child(child)
		child.queue_free()

	if enemies.is_empty():
		# Handle case with no enemies if necessary
		chances_label.text = "No Enemies!"
		return
	
	for i in range(enemies.size()):
		var enemy_group: EnemyGroup = enemies[i]
		print("Adding enemy group: ", enemy_group.enemy.character_name, " with count: ", enemy_group.enemies.size())
		var enemy_display: EnemiesDisplay = enemy_group_scene.instantiate() as EnemiesDisplay
		enemy_display.update_group(enemy_group)
		enemies_display.add_child(enemy_display)
	
	party_strength = _calculate_party_strength()
	enemy_strength = _calculate_enemy_strength()
	
	var odds = _calculate_odds(100000)
	
	chances_label.text = "Victory Chances : " + str(roundi(odds * 100)) +  "%"
	result_label.visible = false
	proceed_button.visible = false
	




func _get_advantage_factor(attacker_class, defender_class):
	if defender_class == "None" :
		return 1.2
	if (attacker_class == "Warrior" and defender_class == "Mage") or \
	   (attacker_class == "Mage" and defender_class == "Rogue") or \
	   (attacker_class == "Rogue" and defender_class == "Warrior"):
		return 1.5  # 50% advantage
	elif (defender_class == "Warrior" and attacker_class == "Mage") or \
		 (defender_class == "Mage" and attacker_class == "Rogue") or \
		 (defender_class == "Rogue" and attacker_class == "Warrior"):
		return 0.5  # 50% disadvantage
	else:
		return 1.0  # No advantage

# Calculate the total effective strength of a party
func _calculate_party_strength():
	var total_strength = 0
	for member in party:
		var advantage_factor = _get_advantage_factor(member.get_char_class(), all_enemies[0].enemy.get_char_class())
		var member_strength = (member.character_level + member.base_damage / 10.0 + member.max_health / 100.0) * advantage_factor
		total_strength += member_strength
	return total_strength

# Calculate the total effective strength of an enemy group
func _calculate_enemy_strength() -> float:
	var total_strength = 0
	for enemy_group in all_enemies:
		var enemy = enemy_group.enemy
		var enemy_char_strength = (enemy.character_level + enemy.base_damage / 10.0 + enemy.max_health / 100.0) * enemy_group.enemies.size()
		total_strength += enemy_char_strength
	return total_strength

# Simulate the fight
func _simulate_fight() -> bool:
	var fight_party_strength = party_strength * randf_range(0.5, 1.5)
	var fight_enemy_strength = enemy_strength * randf_range(0.5, 1.5)
	if fight_party_strength >= fight_enemy_strength:
		return true
	return false
	
func _calculate_odds(simulations: int):
	var wins: float = 0
	for i in range(simulations):
		if _simulate_fight():
			wins += 1

	var win_rate = wins / simulations

	return win_rate

func _on_fight_button_pressed() :
	launch_fight.emit(party, all_enemies)
	
func _on_simulate_button_pressed() :
	fight_result = _simulate_fight()
	if fight_result:
		result_label.text = "Victory !"
	else :
		result_label.text = "Defeat..."
	result_label.visible = true
	proceed_button.visible = true
	
func _on_proceed_button_pressed() :
	resolve_fight.emit(fight_result)
	
func _debug_fight() : 
	if Engine.is_editor_hint():
		party = []
		for char_display in party_display.get_children() : 
			char_display = char_display as CharacterDisplay 
			party.append(char_display.party_member)
			
		all_enemies = [enemies_display.enemy_group]
		
		party_strength = _calculate_party_strength()
		enemy_strength = _calculate_enemy_strength()
	
		var odds: int =  round(_calculate_odds(500000) * 100)
		chances_label.text = "Victory Chances : " + str(odds) + "%"
	
func _on_show_skill_tree(index: int) : 
	character_sheet_ui.show_sheet(party[index])
	background.hide()