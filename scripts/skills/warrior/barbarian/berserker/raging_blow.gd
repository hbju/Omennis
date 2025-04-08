extends MeleeSkill
class_name RagingBlow

var damage_mult := 5
var max_cooldown := 4

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var target = map.get_character(skill_pos)
	if target and target is AICombatCharacter and skill_pos in curr_highlighted_cells:
		var damage = from.get_damage() * damage_mult
		if target.get_health() < target.get_max_health() *3 / 10:
			damage *= 2
		target.take_damage(damage)
		from.attack(map.to_local(target.global_position))
		cooldown = max_cooldown
		return true

	return false
	
func get_skill_name() -> String:
	return "Raging Blow"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your basic damage to an enemy. It the enemy health is below 30%, deal double damage. "

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/raging_blow.png")

func get_skill_range() -> int:
	return 1

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false
	
func is_melee() -> bool:
	return true

