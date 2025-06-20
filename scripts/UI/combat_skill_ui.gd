class_name SkillBarUI
extends TextureRect

const skill_tooltip_scene: PackedScene = preload("res://scenes/skill_tooltip.tscn")
var skill_tooltip_instance: PanelContainer

@onready var button_base_skill = $base_skill_button
@onready var cooldown_base_skill = $base_skill_button/skill_cooldown
@onready var icon_base_skill = $base_skill_button/skill_icon

@onready var button_wait = $wait_button

@onready var button_skills = [
	$skill_button_1,
	$skill_button_2,
	$skill_button_3
]
@onready var cooldown_skills = [
	$skill_button_1/skill_cooldown_1,
	$skill_button_2/skill_cooldown_2,
	$skill_button_3/skill_cooldown_3
]
@onready var icon_skills = [
	$skill_button_1/skill_icon_1,
	$skill_button_2/skill_icon_2,
	$skill_button_3/skill_icon_3
]

var targeting_skill: int = -1
var base_skill: Skill = null
var skill_list: Array[Skill] = []

signal choose_target(skill: Skill)
signal wait_pressed()

var player_turn: bool = false

func _ready() -> void : 
	button_base_skill.pressed.connect(_choose_target.bind(0))
	button_base_skill.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	button_wait.pressed.connect(func () : wait_pressed.emit())
	button_wait.pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))
	for i in range(3):
		button_skills[i].pressed.connect(_choose_target.bind(i+1))
		button_skills[i].pressed.connect(AudioManager.play_sfx.bind(AudioManager.UI_BUTTON_CLICK))

	if skill_tooltip_scene:
		skill_tooltip_instance = skill_tooltip_scene.instantiate()
		add_child(skill_tooltip_instance) 
		skill_tooltip_instance.top_level = true 
		skill_tooltip_instance.hide()
	else:
		printerr("Skill Tooltip Scene not assigned to SkillBarUI!")

	button_base_skill.mouse_entered.connect(_on_skill_button_mouse_entered.bind(0))
	button_base_skill.mouse_exited.connect(_on_skill_button_mouse_exited)
	for i in range(3):
		button_skills[i].mouse_entered.connect(_on_skill_button_mouse_entered.bind(i+1))
		button_skills[i].mouse_exited.connect(_on_skill_button_mouse_exited)
	button_wait.mouse_entered.connect(_on_wait_button_mouse_entered)
	button_wait.mouse_exited.connect(_on_skill_button_mouse_exited)



func update_ui(character: Character, enemy_turn: bool= false ) : 
	player_turn = not enemy_turn

	base_skill = character.base_skill
	self.skill_list = []
	for skill in character.skill_list : 
		self.skill_list.append(skill)

	if base_skill : 
		button_base_skill.modulate = Color(1, 1, 1)
		button_base_skill.show()
		button_base_skill.disabled = enemy_turn
		cooldown_base_skill.show()
		if base_skill.cooldown > 0 : 
			cooldown_base_skill.text = str(base_skill.get_cooldown())
		else : 
			cooldown_base_skill.text = ""
		icon_base_skill.show()
		icon_base_skill.texture = base_skill.get_skill_icon()
	else : 
		button_base_skill.modulate = Color(0.7, 0.7, 0.7)
		button_base_skill.disabled = true
		cooldown_base_skill.hide()
		icon_base_skill.hide()

	for i in range(0, 3) : 
		if i < skill_list.size() : 
			var skill = skill_list[i]
			button_skills[i].modulate = Color(1, 1, 1)
			button_skills[i].show()
			button_skills[i].disabled = enemy_turn
			cooldown_skills[i].show()
			if skill.cooldown > 0 : 
				cooldown_skills[i].text = str(skill.get_cooldown())
			else : 
				cooldown_skills[i].text = ""
			icon_skills[i].show()
			icon_skills[i].texture = skill.get_skill_icon()
		else : 
			button_skills[i].modulate = Color(0.7, 0.7, 0.7)
			button_skills[i].disabled = true
			cooldown_skills[i].hide()
			icon_skills[i].hide()

func reset_ui() : 
	for i in range(0, 3) : 
		button_skills[i].modulate = Color(0.7, 0.7, 0.7)
		button_skills[i].disabled = true
		cooldown_skills[i].hide()
		icon_skills[i].hide()
	button_base_skill.modulate = Color(0.7, 0.7, 0.7)
	button_base_skill.disabled = true
	cooldown_base_skill.hide()
	icon_base_skill.hide()

func _unhandled_input(event):
		
	if event.is_action_pressed("combat_base_skill") :
		if player_turn :
			_choose_target(0)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("combat_wait") :
		if player_turn :
			player_turn = false
			wait_pressed.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("combat_skill_1") && skill_list.size() >= 1 :
		if player_turn : 
			_choose_target(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("combat_skill_2") && skill_list.size() >= 2 :
		if player_turn :
			_choose_target(2)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("combat_skill_3") && skill_list.size() >= 3 :
		if player_turn :
			_choose_target(3)
		get_viewport().set_input_as_handled()
		return

func _choose_target(index: int) : 
	if index == 0 and base_skill.cooldown == 0 : 
		if button_base_skill.modulate == Color(0.7, 0.7, 0.7) : 
			button_base_skill.modulate = Color(1, 1, 1) # Reset color if disabled
		else : 
			button_base_skill.modulate = Color(0.7, 0.7, 0.7) # pushed color if already selected
			for button in button_skills : 
				button.modulate = Color(1, 1, 1) 
		choose_target.emit(base_skill)
		return

	elif index > 0 and skill_list[index-1].get_cooldown() == 0 : 
		if button_skills[index-1].modulate == Color(0.7, 0.7, 0.7) : 
			button_skills[index-1].modulate = Color(1, 1, 1) # Reset color if disabled
		else : 
			button_skills[index-1].modulate = Color(0.7, 0.7, 0.7) # Disable color if already selected
			button_base_skill.modulate = Color(1, 1, 1) # Reset base skill button
			for button in button_skills : 
				if button != button_skills[index-1]: # Reset other buttons
					button.modulate = Color(1, 1, 1)
		choose_target.emit(skill_list[index-1])

func _on_skill_button_mouse_entered(skill_index: int):
	if not skill_tooltip_instance: return # Tooltip doesn't exist
	if skill_index < 0 or skill_index - 1 >= skill_list.size(): return # Invalid index

	skill_tooltip_instance.reset_size()

	var skill: Skill = base_skill if skill_index == 0 else skill_list[skill_index - 1]
	var button: TextureButton = button_base_skill if skill_index == 0 else button_skills[skill_index - 1]

	skill_tooltip_instance.update_content(skill)
	var cd_text = "CD: %d/%d" % [skill.cooldown, skill.max_cooldown]
	if skill_tooltip_instance.has_node("VBoxContainer/CooldownLabel"): # If you add a CD label
		skill_tooltip_instance.get_node("VBoxContainer/CooldownLabel").text = cd_text


	var tooltip_size = skill_tooltip_instance.size
	var viewport_rect = get_viewport_rect()
	var offset = Vector2(0, -10) # Position above the button

	# Calculate position (usually above the button)
	var target_pos = button.global_position + Vector2(button.size.x / 2 - tooltip_size.x / 2, -tooltip_size.y) + offset


	# Adjust if off-screen (simplified)
	if target_pos.x < 0: target_pos.x = 0
	if target_pos.x + tooltip_size.x > viewport_rect.size.x: target_pos.x = viewport_rect.size.x - tooltip_size.x
	if target_pos.y < 0: target_pos.y = button.global_position.y + button.size.y + offset.y # Put below if no space above

	skill_tooltip_instance.position = target_pos
	skill_tooltip_instance.show()

func _on_wait_button_mouse_entered():
	if not skill_tooltip_instance: return # Tooltip doesn't exist

	skill_tooltip_instance.reset_size()

	var skill: Skill = WaitSkill.new()

	skill_tooltip_instance.update_content(skill)

	var tooltip_size = skill_tooltip_instance.size
	var viewport_rect = get_viewport_rect()
	var offset = Vector2(0, -10) # Position above the button

	# Calculate position (usually above the button)
	var target_pos = button_wait.global_position + Vector2(button_wait.size.x / 2 - tooltip_size.x / 2, -tooltip_size.y) + offset


	# Adjust if off-screen (simplified)
	if target_pos.x < 0: target_pos.x = 0
	if target_pos.x + tooltip_size.x > viewport_rect.size.x: target_pos.x = viewport_rect.size.x - tooltip_size.x
	if target_pos.y < 0: target_pos.y = button_wait.global_position.y + button_wait.size.y + offset.y # Put below if no space above

	skill_tooltip_instance.position = target_pos
	skill_tooltip_instance.show()

func _on_skill_button_mouse_exited():
	if skill_tooltip_instance:
		skill_tooltip_instance.hide()
