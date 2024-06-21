extends Skill
class_name BasicSlash

var damage := 60
var max_cooldown := 1

func use_skill(from: CombatCharacter, target: CombatCharacter) -> void:
    target.take_damage(damage)
    cooldown = max_cooldown
    skill_finished.emit()
    
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