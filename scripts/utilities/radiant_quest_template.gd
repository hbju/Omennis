# RadiantQuestTemplate.gd
class_name RadiantQuestTemplate
extends Resource

enum QuestType { KILL, FETCH, DELIVER }

@export var quest_type: QuestType = QuestType.KILL
@export var quest_id_prefix: String = "rad_kill" # Used for unique quest IDs

@export_multiline var title_template: String = ""
@export_multiline var description_template: String = ""

@export_group("Dialogue and Events")
## The text shown when the quest is first offered at the Guild.
@export_multiline var offer_description: String = ""

## The text shown when the player enters the POI *before* completing the objective.
@export_multiline var location_entry_description: String = ""

## The text shown when the player re-enters the POI *after* completing the objective.
@export_multiline var location_post_objective_victory_description: String = "" 

## The text shown when the player re-enters the POI *after* failing the objective.
@export_multiline var location_post_objective_failure_description: String = ""

## The text shown when turning in the quest.
@export_multiline var turn_in_description: String = ""

# --- Requirements ---
@export var location_tag_required: Array[String] = ["cave"] # e.g., "cave", "ruins", "forest_clearing"
@export var min_player_level: int = 1

# --- Quest Specifics ---
# For KILL quests
@export var enemies: Array[Dictionary] = [
    {"archetype": "Brute Marauder", "count": 2, "level": 2},
    {"archetype": "Goblin Raider", "count": 1, "level": 2}
]

# (Future: For FETCH quests)
# @export var item_to_fetch_id: String
# @export var item_location_description: String

# --- Rewards ---
@export_range(50, 500, 5) var reward_gold: int = 100
@export_range(100, 2000, 10) var reward_xp: int = 300

