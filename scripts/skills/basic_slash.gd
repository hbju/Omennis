extends Skill
class_name BasicSlash

var damage_mult := 1
var max_cooldown := 1

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
    var skill_target = map.get_character(skill_pos)
    if not skill_target or not skill_target is AICombatCharacter or HexHelper.distance(map.get_cell_coords(from.global_position), skill_pos) > get_skill_range():
        return false

    skill_target.take_damage(damage_mult * from.get_attack())
    cooldown = max_cooldown
    skill_finished.emit()

    return true
    
func get_skill_name() -> String:
    return "Basic Slash"

func get_skill_description() -> String:
    return "A basic attack that deals 10 damage to a nearby enemy."

func get_skill_icon() -> Texture:
    return load("res://assets/ui/skills/basic_slash.png")

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