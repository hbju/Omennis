extends Skill
class_name ZealousCharge

var damage_mult := 3
var knockback_distance := 1
var knockback_damage_mult := 1
var max_cooldown := 3
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
    var skill_target = map.get_character(skill_pos)
    if skill_pos not in curr_highlighted_cells or skill_target == null or not skill_target is AICombatCharacter:
        return false

    from.attack(map.to_local(skill_target.global_position))
    skill_target.take_damage(damage_mult * from.get_damage())
    skill_target.gain_stunned_status()
    skill_target.knockback(knockback_distance, _get_knockback_dir(from, skill_target, map), knockback_damage_mult * from.get_damage())
    cooldown = max_cooldown
    return true
    
func get_skill_name() -> String:
    return "Zealous Charge"

func get_skill_description() -> String:
    return "Charge a target from two tiles away, dealing " + str(damage_mult) + " times your base damage, stunning them for one turn and knocking them back one tile."

func get_skill_icon() -> Texture:
    return load("res://assets/ui/skills/zealous_charge.png")

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

func highlight_mouse_pos(from: CombatCharacter, _mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
    return highlight_targets(from, map)

func _get_knockback_dir(from: CombatCharacter, target: CombatCharacter, map: CombatMap) -> int:
    var cube_coords_from = HexHelper.axial_to_cube(HexHelper.oddr_to_axial(map.get_cell_coords(from.global_position)))
    var cube_coords_target = HexHelper.axial_to_cube(HexHelper.oddr_to_axial(map.get_cell_coords(target.global_position)))

    if cube_coords_from.x == cube_coords_target.x:
        if cube_coords_from.y < cube_coords_target.y:
            return 5
        else:
            return 2
    if cube_coords_from.y == cube_coords_target.y:
        if cube_coords_from.x < cube_coords_target.x:
            return 0
        else:
            return 3
    if cube_coords_from.z == cube_coords_target.z:
        if cube_coords_from.x < cube_coords_target.x:
            return 1
        else:
            return 4

    return -1