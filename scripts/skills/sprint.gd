extends Skill
class_name Sprint

var damage := 0
var max_cooldown := 2

func use_skill(from: CombatCharacter, target: Vector2i) -> void:
    from.move_to(target)
    
    cooldown = max_cooldown
    
func get_skill_name() -> String:
    return "Sprint"

func get_skill_description() -> String:
    return "Move quickly to a nearby empty space."

func get_skill_icon() -> Texture:
    return load("res://assets/ui/skills/sprint.png")

func get_skill_range() -> int:
    return 2

func target_allies() -> bool:
    return false

func target_enemies() -> bool:
    return false

func target_self() -> bool:
    return false
    
func is_melee() -> bool:
    return true