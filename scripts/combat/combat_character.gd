extends CharacterBody2D
class_name CombatCharacter

var map: CombatMap

var move_target = null
var attack_target = null
var knockback_target = null
var init_pos = null
@export var speed: int = 1000
signal turn_finished

@onready var health_bar = $health_bar
@onready var health_label = $health_bar/curr_health
@onready var shield_bar = $shield_bar
@onready var shield_label = $shield_bar/curr_shield

@onready var character_portrait = $character_portrait_bg/character_portrait
signal character_died(character)

var char_statuses: Dictionary = {"stunned": 0, "poisoned": 0, "burned": 0, "rooted": 0, "vulnerable": 0, "defensive" : 0, "weak": 0, "blessed" : 0, "strong" : 0, "vampiric" : [], "imbue" : [0,0], "thorns" : [0,0], "decay" : [0,0]}

var stunned_animation = preload("res://scenes/stun_animation.tscn")
var curr_stun_animation = null

var character: Character

var health: float = 100
var shield: float = 0
var max_health: float = 100
var base_damage: float = 10

var walkable_cells: Array[int] = []

func _ready() : 
	map = get_parent().get_parent().get_parent()
	character_portrait.texture = load(character.get_portrait_path())
	_update_health_bar()
	_update_shield_bar()


##
## Move to a new target [br]
## If the character is not already moving, set the new target as the move target [br]
## If the character is already moving, ignore the new target [br]
## [code] new_target [/code]: The position of the target character
##
func move_to(new_target) : 
	if not move_target :
		move_target = new_target

##
## Attack a new target [br]
## If the character is not already attacking, set the new target as the attack target [br]
## If the character is already attacking, ignore the new target	[br]
## [code] new_target [/code]: The position of the target character [br]
## [code] ranged [/code]: If the attack is ranged or not
##
func attack(new_target: Vector2i, ranged: bool = false) :
	if not attack_target :
		attack_target = new_target
		if ranged : 
			init_pos = position
		else : 
			var path = _calculate_path_to_character(map.local_to_map(new_target))
			init_pos = map.map_to_local(path[path.size() - 2])

func _physics_process(_delta):
	if not move_target and not attack_target and not knockback_target : 
		return

	if move_target :	
		move_to_target()
	elif attack_target :
		move_to_attack_target()
	elif knockback_target : 
		knock_to_target()

##
## Move the character to the move target [br]
## If the character is close enough to the target, finish the turn
##
func move_to_target() :
	velocity = position.direction_to(move_target) * speed
	if position.distance_to(move_target) > 50:
		move_and_slide()
	else :
		finish_turn()

func knock_to_target() :
	velocity = position.direction_to(knockback_target) * speed
	if position.distance_to(knockback_target) > 50:
		move_and_slide()
	else :
		knockback_target = null

##
## Move the character to the attack target [br]
## If the character is close enough to the target, moves the character back to the initial position [br]
##
func move_to_attack_target() :		
	z_index = 10
	velocity = position.direction_to(attack_target) * speed
	if position.distance_to(attack_target) > 50:
		move_and_slide()
	else :
		if init_pos :
			attack_target = init_pos
			init_pos = null
		else :
			finish_turn()

##
## Decrease the health of the character by the damage taken [br]
## Update the health bar [br]
## If the health is less than or equal to 0, emit the character_died signal
## [code] damage_taken [/code]: The amount of base_damage taken
##
func take_damage(damage_taken: float) -> float :
	if char_statuses["defensive"] > 0 : 
		damage_taken = damage_taken / 2
	if char_statuses["vulnerable"] > 0 : 
		damage_taken = damage_taken * 3/2

	if shield > 0 :
		if shield >= damage_taken : 
			shield -= damage_taken
			damage_taken = 0
		else : 
			damage_taken -= shield
			shield = 0

	health -= damage_taken

	_update_health_bar()
	_update_shield_bar()

	if health <= 0 :
		queue_free()
		character_died.emit(self)
	
	return damage_taken

##
## Decrease the health of the character by the health_spent. Ignore statuses and shield. [br]
## Update the health bar [br]
## If the health is less than or equal to 0, emit the character_died signal
## [code] health_spent [/code]: The amount of health to spend
##
func spend_health(health_spent: float) : 
	health -= health_spent
	_update_health_bar()

	if health <= 0 :
		queue_free()
		character_died.emit(self)

##
## Heal the character by the heal_amount [br]
## If the character is blessed, the heal_amount is increased by 10% times the level of blessed [br]
## [code] heal_amount [/code]: The amount of health to heal
##
func heal(heal_amount: float) -> float: 
	var blessed_lvl = char_statuses["blessed"]
	if blessed_lvl > 0 : 
		heal_amount = heal_amount * (1 + blessed_lvl/10.0)
	print(str(heal_amount), " ", str(health + heal_amount), " ", str(max_health))
	health = min(max_health, health + heal_amount)
	_update_health_bar()

	return heal_amount

##
## Gain shield up to the max health of the character [br]
## [code] shield_percentage [/code]: The percentage of max_health to gain as shield
##
func gain_shield(shield_percentage: float) -> float:
	return gain_shield_flat(max_health * shield_percentage / 100.0)

##
## Gain shield up to the max health of the character [br]
## [code] shield_amount [/code]: The amount of shield to gain
## [code] return [/code]: The amount of shield gained
##
func gain_shield_flat(shield_amount: float) -> float:
	var old_value = shield 
	shield = min(max_health, shield + shield_amount)
	_update_shield_bar()
	return shield - old_value

##
## Update the health bar [br]
## The health bar value is the health divided by the max_health [br]
## The health label is the health divided by the max_health
##
func _update_health_bar() : 
	health_bar.value = (health / max_health) * health_bar.max_value
	health_label.text = str(roundi(health)) + "/" + str(max_health)

func _update_shield_bar() : 
	if shield <= 0 : 
		shield_bar.visible = false
		shield_label.visible = false
	else : 
		shield_bar.visible = true
		shield_label.visible = true
		shield_bar.max_value = max_health
		shield_bar.value = (shield / max_health) * shield_bar.max_value
		shield_label.text = str(roundi(shield)) + "/" + str(max_health)

##
## Get the amount of damage the character will deal on the next attack [br]
## If the character is weak, the base_damage is reduced by a third [br]
## [code] return [/code]: The amount of base_damage the character can deal
##
func get_damage() -> float :
	var damage =  base_damage + char_statuses["imbue"][1] if char_statuses["imbue"][0] > 0 else base_damage
	if char_statuses["weak"] > 0 : 
		damage = damage * 2 / 3
	if char_statuses["strong"] > 0 : 
		damage = damage * 3 / 2
	return damage

func deal_damage(other: CombatCharacter, damage_mult: float) -> float : 
	var damage = get_damage() * damage_mult
	other.take_damage(damage)

	if (other.char_statuses["thorns"][0] > 0) :
		take_damage(other.char_statuses["thorns"][1])

	if char_statuses["vampiric"].size() > 0 : 
		var vampiric_stats = char_statuses["vampiric"]
		var vampiric_level = 0
		for i in range(vampiric_stats.size()) : 
			if vampiric_stats[i][0] > 0 : 
				vampiric_level += vampiric_stats[i][1]
		heal(damage * vampiric_level / 100.0)

	return damage

func take_turn() : 
	assert(false, "take_turn not implemented")

##
## Finish the turn [br]
## Reset the move target and attack target [br]
## Emit the turn_finished signal
##
func finish_turn() : 
	z_index = 0
	attack_target = null
	move_target = null
	char_statuses["defensive"] = max(0, char_statuses["defensive"] - 1)
	char_statuses["vulnerable"] = max(0, char_statuses["vulnerable"] - 1)
	char_statuses["rooted"] = max(0, char_statuses["rooted"] - 1)
	char_statuses["weak"] = max(0, char_statuses["weak"] - 1)
	char_statuses["strong"] = max(0, char_statuses["strong"] - 1)
	char_statuses["imbue"][0] = max(0, char_statuses["imbue"][0] - 1)
	var new_vampiric = []
	for i in range(char_statuses["vampiric"].size()) : 
		char_statuses["vampiric"][i][0] = char_statuses["vampiric"][i][0] - 1
		if char_statuses["vampiric"][i][0] > 0 : 
			new_vampiric.append(char_statuses["vampiric"][i])
	char_statuses["vampiric"] = new_vampiric
	char_statuses["decay"][0] = max(0, char_statuses["decay"][0] - 1)
	char_statuses["thorns"][0] = max(0, char_statuses["thorns"][0] - 1)

	if char_statuses["decay"][0] > 0 : 
		take_damage(char_statuses["decay"][1] * max_health / 100.0)

	
	turn_finished.emit()

##
## Calculate the path to the target character using the A* algorithm [br]
## [code] other_char_pos [/code]: The position of the target character [br]
## [code] return [/code]: The path to the target character
##
func _calculate_path_to_character(other_char_pos: Vector2i) -> PackedVector2Array:
	var this_tile_id = map.cell_ids[map.get_cell_coords(global_position)]
	var target_tile_id = map.cell_ids[other_char_pos]
	return map.astar.get_point_path(this_tile_id, target_tile_id)

##
## Stun the character, making him skip his next turn [br]
##
func gain_stunned_status(nb_turns: int = 1) : 
	char_statuses["stunned"] = nb_turns
	curr_stun_animation = stunned_animation.instantiate()
	add_child(curr_stun_animation)
	curr_stun_animation.position = Vector2(0, 0)
	curr_stun_animation.z_index = 10
	curr_stun_animation.play()

func gain_rooted_status(nb_turns: int = 1) : 
	char_statuses["rooted"] = max(nb_turns, char_statuses["rooted"])

func gain_defensive_status(nb_turns: int = 1) : 
	char_statuses["defensive"] = nb_turns
	if char_statuses["vulnerable"] > 0 : 
		char_statuses["vulnerable"] = 0

func gain_weak_status(nb_turns: int = 1) :
	char_statuses["weak"] = nb_turns
	if char_statuses["strong"] > 0 : 
		char_statuses["strong"] = 0

func gain_blessed_status(nb_level: int = 1) : 
	char_statuses["blessed"] = nb_level

func gain_strong_status(nb_turns: int = 1) : 
	char_statuses["strong"] = nb_turns
	if char_statuses["weak"] > 0 : 
		char_statuses["weak"] = 0

func gain_imbue_status(nb_turns: int = 1, imbue_strength: int = 10) :
	char_statuses["imbue"][0] = nb_turns
	char_statuses["imbue"][1] = imbue_strength

func gain_vulnerable_status(nb_turns: int = 1) : 
	char_statuses["vulnerable"] = nb_turns
	if char_statuses["defensive"] > 0 : 
		char_statuses["defensive"] = 0

func gain_vampiric_status(nb_turns: int = 1, nb_levels: int = 1) : 
	char_statuses["vampiric"].append([nb_turns, nb_levels])

func gain_thorn_status(nb_turns: int = 1, nb_levels: int = 1) :
	char_statuses["thorns"][0] = char_statuses["thorns"][0] + nb_turns
	char_statuses["thorns"][1] = max(char_statuses["thorns"][1], nb_levels)

func gain_decay_status(nb_turns: int = 1, decay_percent: int = 10) :
	char_statuses["decay"][0] = max(char_statuses["decay"][0], nb_turns)
	char_statuses["decay"][1] = char_statuses["decay"][1] + decay_percent

func knockback(knockback_distance: int, direction: int, knockback_damage: float) : 
	var curr_pos = map.get_cell_coords(global_position)
	var knock_target = curr_pos
	var knocked = false
	var knock_char = null
	for i in range(knockback_distance) : 
		var neighbour = HexHelper.hex_neighbor(knock_target, direction)
		if not map.can_walk(neighbour) or map.cell_occupied(neighbour) : 
			knocked = true
			knock_char = map.get_character(neighbour)
			break
		knock_target = neighbour
	knockback_target = map.map_to_local(knock_target)
	if knocked : 
		take_damage(knockback_damage)


