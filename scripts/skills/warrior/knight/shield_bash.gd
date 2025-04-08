extends MeleeSkill
class_name ShieldBash

var damage_mult := 2
var max_cooldown := 3

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
	var target = map.get_character(skill_pos)
	if target and target is AICombatCharacter and HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) == 1:
		target.gain_weak_status(2)
		target.take_damage(from.get_damage() * damage_mult)
		from.attack(map.to_local(target.global_position))
		cooldown = max_cooldown
		skill_finished.emit()
		return true

	return false
	
func get_skill_name() -> String:
	return "Defensive Stance"

func get_skill_description() -> String:
	return "Deal " + str(damage_mult) + " times your base damage and reduce the enemy’s damage by 33% for 2 turns. "

func get_skill_icon() -> Texture:
	return load("res://assets/ui/skills/shield_bash.png")

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

