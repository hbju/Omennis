extends MeleeSkill
class_name HolyStrike

var damage_mult := 4
var max_cooldown := 4

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var target = map.get_character(skill_pos)
	if target and target is AICombatCharacter and skill_pos in curr_highlighted_cells:
		var damage = from.get_damage() * damage_mult
		from.deal_damage(target, damage_mult)
		from.heal(damage / 4.0)
		from.attack(map.to_local(target.global_position))
		cooldown = max_cooldown
		return true

	return false
	
func get_skill_name() -> String:
	return "Holy Strike"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " 4 times your basic damage to an enemy and heal yourself for 25% of the damage dealt.
 "

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/holy_strike.png")

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

