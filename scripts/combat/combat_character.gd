extends CharacterBody2D
class_name CombatCharacter

var map: CombatMap

var move_target = null
var attack_target = null
var knockback_target = null
var init_pos = null
@export var speed: int = 1000

signal turn_finished
signal hover_entered(character)
signal hover_exited(character)

@onready var health_bar = $health_bar
@onready var health_label = $health_bar/curr_health
@onready var shield_bar = $shield_bar
@onready var shield_label = $shield_bar/curr_shield
@onready var status_effects_container: BoxContainer = $status_effects_container
@onready var character_highlight = $character_portrait_bg/character_background

const StatusIconScene = preload("res://scenes/status_icon.tscn")
const STATUS_ICON_MAP = {
	"stunned": "res://assets/ui/status/stunned_icon.png",
	"defensive": "res://assets/ui/status/defensive_icon.png",
	"weak": "res://assets/ui/status/weak_icon.png",
	"strong": "res://assets/ui/status/strong_icon.png",
	"vulnerable": "res://assets/ui/status/vulnerable_icon.png",
	"rooted": "res://assets/ui/status/rooted_icon.png",
	"decay": "res://assets/ui/status/decay_icon.png",
	"thorns": "res://assets/ui/status/thorns_icon.png",
	"blessed": "res://assets/ui/status/blessed_icon.png",
	 "leech": "res://assets/ui/status/leech_icon.png",
	 "imbue": "res://assets/ui/status/imbue_icon.png" 
}

@onready var character_portrait = $character_portrait_bg/character_portrait
signal character_died(character)

var char_statuses: Dictionary = {"stunned": 0, "rooted": 0, "vulnerable": 0, "defensive" : 0, "weak": 0, "blessed" : 0, "strong" : 0, "leech" : [], "imbue" : [0,0], "thorns" : [0,0], "decay" : [0,0]}

var stunned_animation = preload("res://scenes/stun_animation.tscn")
var curr_stun_animation = null

var character: Character


var shield: float = 0
var max_health: float = 100
var health: float = 100
var base_damage: float = 10

var walkable_cells: Array[int] = []

func _ready() : 
	map = get_parent().get_parent().get_parent()
	character_portrait.texture = load(character.get_portrait_path())
	max_health = character.max_health
	health = character.max_health
	base_damage = character.base_damage
	_update_health_bar()
	_update_shield_bar()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	call_deferred("update_status_icons")


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
		position = move_target
		finish_turn()

func knock_to_target() :
	velocity = position.direction_to(knockback_target) * speed
	if position.distance_to(knockback_target) > 50:
		move_and_slide()
	else :
		position = knockback_target
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
		position = attack_target
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

	if char_statuses["leech"].size() > 0 : 
		var leech_stats = char_statuses["leech"]
		var leech_level = 0
		for i in range(leech_stats.size()) : 
			if leech_stats[i][0] > 0 : 
				leech_level += leech_stats[i][1]
		heal(damage * leech_level / 100.0)

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
	var new_leech = []
	for i in range(char_statuses["leech"].size()) : 
		char_statuses["leech"][i][0] = char_statuses["leech"][i][0] - 1
		if char_statuses["leech"][i][0] > 0 : 
			new_leech.append(char_statuses["leech"][i])
	char_statuses["leech"] = new_leech
	char_statuses["decay"][0] = max(0, char_statuses["decay"][0] - 1)
	char_statuses["thorns"][0] = max(0, char_statuses["thorns"][0] - 1)

	if char_statuses["decay"][0] > 0 : 
		take_damage(char_statuses["decay"][1] * max_health / 100.0)

	update_status_icons()
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

func gain_status(status_name: String, nb_turns: int = 1, nb_level: int = 0) :
	match status_name : 
		"stunned" : 
			gain_stunned_status(nb_turns)
		"rooted" : 
			gain_rooted_status(nb_turns)
		"defensive" : 
			gain_defensive_status(nb_turns)
		"weak" : 
			gain_weak_status(nb_turns)
		"blessed" : 
			gain_blessed_status(nb_level)
		"strong" : 
			gain_strong_status(nb_turns)
		"imbue" : 
			gain_imbue_status(nb_turns, nb_level)
		"vulnerable" : 
			gain_vulnerable_status(nb_turns)
		"leech" :
			gain_leech_status(nb_turns, nb_level)
		"thorns":
			gain_thorn_status(nb_turns, nb_level)
		"decay":
			gain_decay_status(nb_turns, nb_level)

	update_status_icons()

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

func gain_leech_status(nb_turns: int = 1, nb_levels: int = 1) : 
	char_statuses["leech"].append([nb_turns, nb_levels])

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
	for i in range(knockback_distance) : 
		var neighbour = HexHelper.hex_neighbor(knock_target, direction)
		if not map.can_walk(neighbour) or map.cell_occupied(neighbour) : 
			knocked = true
			break
		knock_target = neighbour
	knockback_target = map.map_to_local(knock_target)
	if knocked : 
		take_damage(knockback_damage)


## UI

func _on_mouse_entered() : 
	hover_entered.emit(self)

func _on_mouse_exited() :
	hover_exited.emit(self)

func update_status_icons():
	if not is_inside_tree() or not status_effects_container: # Safety check
		return

	# Clear previous icons
	for child in status_effects_container.get_children():
		child.queue_free()

	# Add icons for current statuses
	for status_name in char_statuses.keys():
		var status_value = char_statuses[status_name]
		var show_icon = false
		var duration = -1
		var level = -1

		# Determine if the status is active and get display value
		match status_name:
			"leech":
				if status_value is Array and not status_value.is_empty():
					show_icon = true
					for i in range(status_value.size()):
						if status_value[i][0] > 0:
							show_icon = true
							duration += status_value[i][0] # Show duration
							level = max(status_value[i][1], level) # Show level
			"imbue", "thorns", "decay":
				if status_value is Array and status_value[0] > 0: # Check duration part
					show_icon = true
					duration = status_value[0] # Show duration
					level = status_value[1] # Show level
			_: # Default for simple duration/level statuses
				if status_value is int and status_value > 0:
					show_icon = true
					duration = status_value

		 # Instantiate and add icon if active
		if show_icon and STATUS_ICON_MAP.has(status_name):
			if StatusIconScene:
				var icon_instance = StatusIconScene.instantiate()
				icon_instance.call_deferred("set_data", load(STATUS_ICON_MAP[status_name]), duration, level)
				icon_instance.name = status_name
				
				status_effects_container.add_child(icon_instance)
				# Optional: Add tooltip to the icon instance here
				# icon_instance.tooltip_text = get_status_description(status_name)
			else:
				printerr("StatusIconScene not loaded!")

func set_highlight(is_highlighted: bool, color: Color = Color(0xffcd12ff)):
	if character_highlight:
		character_highlight.visible = is_highlighted
		character_highlight.color = color
	else :
		printerr("Character highlight not found!")
