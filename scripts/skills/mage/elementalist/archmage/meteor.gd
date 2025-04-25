extends Skill
class_name Meteor

var total_damage_mult := 12
var aoe_radius := 1
var max_cooldown := 5

const meteor_scene = preload("res://scenes/impact_effect.tscn")
var curr_meteor: ImpactEffect 
var targets: Array[CombatCharacter] = []
var caster: CombatCharacter
var curr_highlighted_cells: Array[Vector2i] = []
var curr_aoe_highlight: Array[Vector2i] = []


func use_skill(from: CombatCharacter, skill_pos: Vector2i, map: CombatMap) -> bool:
    caster = from
    targets = []
    var caster_pos = map.get_cell_coords(from.global_position)
    if HexHelper.distance(caster_pos, skill_pos) > get_skill_range():
        return false

    # Find all characters in the AoE centered on skill_pos
    var impact_cells = HexHelper.hex_reachable(skill_pos, aoe_radius, func(_hex): return true)
    for cell in impact_cells:
        var character = map.get_character(cell)
        if character:
            targets.append(character)

    if targets.is_empty():
        return false

    # Play visual effect at skill_pos
    curr_meteor = meteor_scene.instantiate()
    map.add_child(curr_meteor) 
    curr_meteor.position = map.map_to_local(skill_pos)
    curr_meteor.scale = Vector2(6, 6)
    curr_meteor.set_impact_type("thunderstrike")
    curr_meteor.animated_sprite.animation_looped.connect(_apply_effect)

    cooldown = max_cooldown
    return true

func _apply_effect(): 
    var damage_mult = total_damage_mult / (len(targets)*1.0)
    for target in targets : 
        caster.deal_damage(target, damage_mult)
    curr_meteor.queue_free()
    skill_finished.emit()

func get_skill_name() -> String:
    return "Meteor"

func get_skill_description() -> String:
    return "Deal " + str(total_damage_mult) + " times your base damage divided between all characters in a " + str(aoe_radius) + "-cell radius around the target location."

func get_skill_icon() -> Texture:
    return load("res://assets/ui/skills/meteor.png") # Placeholder path

func get_skill_range() -> int:
    return 4

func target_allies() -> bool:
    return true # Can hit allies in blast

func target_enemies() -> bool:
    return true # Can hit enemies in blast

func target_self() -> bool:
    return true # Can hit self if targeted nearby

func is_melee() -> bool:
    return false

func highlight_targets(from: CombatCharacter, map: CombatMap) -> Array[Vector2i]:
    var caster_pos = map.get_cell_coords(from.global_position)
    curr_highlighted_cells = HexHelper.hex_reachable(caster_pos, get_skill_range(), func(_hex: Vector2i): return true).filter(func (cell): return map.can_walk((cell)))

    for cell in curr_highlighted_cells:
        map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)

    return curr_highlighted_cells

func highlight_mouse_pos(_from: CombatCharacter, mouse_pos: Vector2i, map: CombatMap) -> Array[Vector2i]:
    map.reset_map()
    for cell in curr_highlighted_cells:
        map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 3)

    # If mouse is over a valid center point, highlight the AoE
    if mouse_pos in curr_highlighted_cells:
        map.set_cell(0, mouse_pos, 22, map.get_cell_atlas_coords(0, mouse_pos), 4) # Hovered target cell
        curr_aoe_highlight = HexHelper.hex_reachable(mouse_pos, aoe_radius, func(hex): return map.can_walk(hex))

        for cell in curr_aoe_highlight:
            var character = map.get_character(cell)
            if character:
                map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 5)
            else:
                map.set_cell(0, cell, 22, map.get_cell_atlas_coords(0, cell), 4)

    return curr_highlighted_cells # Return the valid center points