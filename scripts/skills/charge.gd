extends Skill
class_name Charge

var damage := 30
var max_cooldown := 3

func use_skill(from: CombatCharacter, skill_target: CombatCharacter) -> void:

    from.attack(skill_target.map.to_local(skill_target.global_position))
    skill_target.take_damage(damage)
    skill_target.stun()
    cooldown = max_cooldown
    
func get_skill_name() -> String:
    return "Charge"

func get_skill_description() -> String:
    return "Charge a target from two tiles away, dealing " + str(damage) + " damage."

func get_skill_icon() -> Texture:
    return load("res://assets/ui/skills/basic_slash.png")

func get_skill_range() -> int:
    return 3

func target_allies() -> bool:
    return false

func target_enemies() -> bool:
    return true

func target_self() -> bool:
    return false
    
func is_melee() -> bool:
    return false