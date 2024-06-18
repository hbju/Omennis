class_name Skill

var cooldown: int
signal skill_finished()

func decrease_cooldown():
	if cooldown > 0:
		cooldown -= 1

func use_skill(_from: CombatCharacter, _target: CombatCharacter):
	assert(false, "function not implemented")
	pass

func get_skill_name() -> String:
	assert(false, "function not implemented")
	return ""

func get_skill_description() -> String:
	assert(false, "function not implemented")
	return ""

func get_skill_icon() -> Texture:
	assert(false, "function not implemented")
	return null

func get_skill_range() -> int:
	assert(false, "function not implemented")
	return -1

func target_allies() -> bool:
	assert(false, "function not implemented")
	return false

func target_enemies() -> bool:
	assert(false, "function not implemented")
	return false

func get_cooldown() -> int:
	return cooldown

func is_melee() -> bool:
	assert(false, "function not implemented")
	return false
