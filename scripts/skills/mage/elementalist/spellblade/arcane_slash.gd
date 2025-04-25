extends MeleeSkill # Inherits range 1, is_melee, basic highlighting
class_name ArcaneSlash

var damage_mult := 3
var shield_gain_mult := 0.5 # Gain half of damage_mult dealt
var max_cooldown := 3

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var skill_target = map.get_character(skill_pos)
	if not skill_target or not skill_target is AICombatCharacter or not skill_pos in curr_highlighted_cells:
		return false 

	from.deal_damage(skill_target, damage_mult)
	from.gain_shield(damage_mult * shield_gain_mult * from.get_damage())
	from.attack(map.to_local(skill_target.global_position))


	cooldown = max_cooldown
	skill_finished.emit()
	return true

func get_skill_name() -> String:
	return "Arcane Slash"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage to an enemy, gain " + str(int(shield_gain_mult * 100)) + "% of damage dealt as shield." # Armor -> Shield

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/arcane_slash.png")

func target_allies() -> bool:
	return false

func target_enemies() -> bool:
	return true

func target_self() -> bool:
	return false
