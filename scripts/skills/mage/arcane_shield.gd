extends Skill
class_name ArcaneShield

var duration := 1
var reduction_percent := 50
var max_cooldown := 3
var curr_highlighted_cells: Array[Vector2i] = []

func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
    var skill_target = map.get_character(skill_pos)
    var caster_pos = map.get_cell_coords(from.global_position)

    if HexHelper.distance(caster_pos, skill_pos) > get_skill_range():
        return false

    if skill_pos == caster_pos:
        skill_target = from
    elif not skill_target or not skill_target is PlayerCombatCharacter:
        return false

    skill_target.gain_defensive_status(duration + 1 if skill_target == from else duration)
    cooldown = max_cooldown
    skill_finished.emit()
    return true

func get_skill_name() -> String:
    return "Arcane Shield"

func get_skill_description() -> String:
    return "Create a magical shield around an ally within a " + str(get_skill_range()) + "-cell radius or yourself that reduces incoming damage by " + str(reduction_percent) + "% for " + str(duration) + " turn."

func get_skill_icon() -> Texture:
    return load("res://assets/ui/skills/arcane_shield.png") # Placeholder path

func get_skill_range() -> int:
    return 2

func target_allies() -> bool:
    return true

func target_enemies() -> bool:
    return false

func target_self() -> bool:
    return true

func is_melee() -> bool:
    return false

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
    var caster_pos = map.get_cell_coords(from.global_position)
    var can_target = func(hex: Vector2i): return map.can_walk(hex)
    curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), can_target)

    var valid_targets: Array[Vector2i] = []
    for cell in curr_highlighted_cells:
        map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)
        var character = map.get_character(cell)
        if cell == caster_pos or (character and character is PlayerCombatCharacter):
             map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
             valid_targets.append(cell)
        elif character and character is AICombatCharacter:
             map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 0) 

    curr_highlighted_cells = valid_targets
    return curr_highlighted_cells

func highlight_mouse_pos(from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
    var caster_pos = map.get_cell_coords(from.global_position)
    # Re-highlight potential range first
    var potential_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(hex: Vector2i): return map.can_walk(hex))
    for cell in potential_cells:
         map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 6)

    # Highlight actual targets and hover effect
    for cell in curr_highlighted_cells: # Iterate only over valid targets
        var character = map.get_character(cell)
        var is_self = (cell == caster_pos)
        var is_ally = character and character is PlayerCombatCharacter

        if is_self or is_ally:
             map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 7)
             if mouse_pos == cell:
                map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 8)

    return curr_highlighted_cells
