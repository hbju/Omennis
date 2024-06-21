class_name Skill

var cooldown: int
signal skill_finished()

## Skill functions

##
## Decrease the cooldown of the skill by 1
##
func decrease_cooldown():
	if cooldown > 0:
		cooldown -= 1

##
## Make _from use the skill on _target. This function should be overriden by the child class
##
## [code] _from [/code]: The CombatCharacter that is using the skill
## [code] _target [/code]: The CombatCharacter that is being targeted by the skill
##
func use_skill(_from: CombatCharacter, _target):
	assert(false, "function not implemented")
	pass

##
## Get the name of the skill
##
func get_skill_name() -> String:
	assert(false, "function not implemented")
	return ""

##
## Get the description of the skill
##
func get_skill_description() -> String:
	assert(false, "function not implemented")
	return ""

##
## Get the icon of the skill
##
func get_skill_icon() -> Texture:
	assert(false, "function not implemented")
	return null

##
## Get the range of the skill
##
func get_skill_range() -> int:
	assert(false, "function not implemented")
	return -1

##
## Get whether the skill targets allies, enemies, or self
##
func target_allies() -> bool:
	assert(false, "function not implemented")
	return false

func target_enemies() -> bool:
	assert(false, "function not implemented")
	return false

func target_self() -> bool:
	assert(false, "function not implemented")
	return false

##
## Get the remaining cooldown of the skill
##
func get_cooldown() -> int:
	return cooldown

##
## Get whether the skill is a melee skill
##
func is_melee() -> bool:
	assert(false, "function not implemented")
	return false
