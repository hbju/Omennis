# target_info.gd (or within skill.gd)
class_name TargetInfo

enum TargetType {
	CHARACTER,          # Targets a specific character (e.g., Basic Slash, Firespark)
	CELL,               # Targets an empty cell (e.g., Sprint)
	AOE_LOCATION,       # Targets a cell as the center of an AoE (e.g., Meteor)
	SELF_CAST,          # Targets only the caster (e.g., Defensive Stance, Molten Blade)
	SELF_AOE_ACTIVATION # Activates an AoE centered on the caster (e.g., Whirlwind, Soul Harvest)
}

var type: TargetType
var primary_target: CombatCharacter        # The main char target/caster (null for CELL, AOE_LOCATION)
var target_cell: Vector2i            # The cell being targeted or the center of the AoE
var affected_targets: Array[CombatCharacter] # Pre-calculated list of characters hit by this specific action

func _init(p_type: TargetType, p_target: CombatCharacter, p_cell: Vector2i, p_affected: Array[CombatCharacter]):
	type = p_type
	primary_target = p_target
	target_cell = p_cell
	affected_targets = p_affected

func _to_string() -> String: # Optional: for debugging
	return "TargetInfo(Type: %s, Cell: %s, Primary: %s, Affected: %s)" % [TargetType.keys()[type], str(target_cell), primary_target.character.character_name if primary_target else "None", str(affected_targets.size())]