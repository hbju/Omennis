extends Skill
class_name Charge

var damage := 30
var max_cooldown := 3
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
    var skill_target = map.get_character(skill_pos)
    if skill_target == null or not skill_target is AICombatCharacter:
        return false

    from.attack(skill_target.map.to_local(skill_target.global_position))
    skill_target.take_damage(damage)
    skill_target.stun()
    cooldown = max_cooldown
    return true
    
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

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
    curr_highlighted_cells = map.highlight_columns(map.get_cell_coords(from.global_position), get_skill_range())
    return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, _mouse_pos: Vector2i, _map: CombatMap) -> Array[Vector2i]:
    return highlight_targets(_from, _map)