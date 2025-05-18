@tool
extends Control
class_name FightUI

@onready var party_display = $bg/party_display
@onready var enemies_display: EnemiesDisplay = $bg/enemies_display
@onready var chances_label = $bg/chances_bg/chances_label
@onready var result_label = $bg/result_label
@onready var fight_button = $bg/fight_button
@onready var simulation_button = $bg/simulation_button
@onready var flee_button = $bg/flee_button
@onready var proceed_button = $bg/proceed_button

@export var debug_fight = false : 
	set(value) : 
		_debug_fight()

signal launch_fight(party: Array[PartyMember], enemy_group: EnemyGroup)
signal resolve_fight(fight_ccl: String)
signal show_skill_tree(index: int)

var fight_result = false

var party: Array[PartyMember]
var enemy_group: EnemyGroup

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
	
	
func update_ui(_party: Array[PartyMember], _enemy_group: EnemyGroup) :
	self.party = _party
	self.enemy_group = _enemy_group
	
	var displays = party_display.get_children()
	for i in range(0, _party.size()):
		var display: CharacterDisplay = displays[i]
		display.update_character(_party[i])
		display.visible = true
		display.show_delete_button = false
	for i in range(_party.size(), 4) :
		displays[i].visible = false
	
	enemies_display.update_group(_enemy_group)
	
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
		var advantage_factor = _get_advantage_factor(member.get_char_class(), enemy_group.enemy.get_char_class())
		var member_strength = member.character_level * advantage_factor
		total_strength += member_strength
	return total_strength

# Calculate the total effective strength of an enemy group
func _calculate_enemy_strength() -> float:
	return enemy_group.enemy.character_level * enemy_group.enemies.size()

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
	launch_fight.emit(party, enemy_group)
	
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
			
		enemy_group = enemies_display.enemy_group
		
		party_strength = _calculate_party_strength()
		enemy_strength = _calculate_enemy_strength()
	
		var odds: int =  round(_calculate_odds(500000) * 100)
		chances_label.text = "Victory Chances : " + str(odds) + "%"
	
func _on_show_skill_tree(index: int) : 
	show_skill_tree.emit(index)