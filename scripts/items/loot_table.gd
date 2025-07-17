class_name LootTable
extends Resource

@export var entries: Dictionary[BaseItem, Vector2i] = {}
@export_range(0, 100) var item_drop_chance : int = 0

const DROP_CHANCE_STEEPNESS_INFERIOR: float = 1.5
const DROP_CHANCE_STEEPNESS_SUPERIOR: float = 0.9
const DROP_CHANCE_MIDPOINT_OFFSET_INFERIOR: float = -2.0
const DROP_CHANCE_MIDPOINT_OFFSET_SUPERIOR: float = 4.0
const BASE_WEIGHTS : Dictionary[BaseItem.ItemTier, int] = {
	BaseItem.ItemTier.COMMON: 54,
	BaseItem.ItemTier.UNCOMMON: 33,
	BaseItem.ItemTier.RARE: 8,
	BaseItem.ItemTier.EPIC: 4,
	BaseItem.ItemTier.LEGENDARY: 1
}

func loot_sigmoid(base_chance: float, player_level: int, item_level: int) -> float:
	var level_difference = player_level - item_level
	var level_modifier = 1.0

	if level_difference < 0:
		level_modifier = (1 / (1 + exp(-DROP_CHANCE_STEEPNESS_INFERIOR * (level_difference - DROP_CHANCE_MIDPOINT_OFFSET_INFERIOR))))
	elif level_difference > 0:
		level_modifier = (1 / (1 + exp(DROP_CHANCE_STEEPNESS_SUPERIOR * (level_difference - DROP_CHANCE_MIDPOINT_OFFSET_SUPERIOR))))

	var drop_chance = base_chance * level_modifier

	return drop_chance

func final_loot_chances(mob_level: int) -> Dictionary[BaseItem, float]:
	var final_chances: Dictionary[BaseItem, float] = {}
	if entries.is_empty():
		return final_chances
	
	var total_each_tier: Dictionary[BaseItem.ItemTier, int] = {
		BaseItem.ItemTier.COMMON: 0,
		BaseItem.ItemTier.UNCOMMON: 0,
		BaseItem.ItemTier.RARE: 0,
		BaseItem.ItemTier.EPIC: 0,
		BaseItem.ItemTier.LEGENDARY: 0
	}
	
	for item in entries:
		var item_tier: BaseItem.ItemTier = item.tier
		if item_tier in total_each_tier:
			total_each_tier[item_tier] += 1

	for item in entries:
		var base_chance: float = 1.0 / total_each_tier[item.tier]
		var item_level: int = item.item_lvl
		var final_weight: float = loot_sigmoid(base_chance, mob_level, item_level)
		final_chances[item] = final_weight

	return final_chances

func roll_for_loot(mob_level: int) -> Array:
	if entries.is_empty():
		return []

	if item_drop_chance <= 0 or randf() * 100 > item_drop_chance:
		return []

	var loot_chances: Dictionary[BaseItem, float] = final_loot_chances(mob_level)

	var item_tier: BaseItem.ItemTier = BaseItem.ItemTier.COMMON
	var tiers_total_weight: int = 0
	for tier in BASE_WEIGHTS:
		tiers_total_weight += BASE_WEIGHTS[tier]
	var tier_roll: int = randi() % tiers_total_weight
	var cumulative_weight: float = 0.0
	for tier in BASE_WEIGHTS:
		cumulative_weight += BASE_WEIGHTS[tier]
		if tier_roll < cumulative_weight:
			item_tier = tier
			break

	var final_chances: Dictionary[BaseItem, float] = {}
	for item in loot_chances:
		if item.tier == item_tier:
			final_chances[item] = loot_chances[item]

	var total_weight: float = 0.0
	for item in final_chances:
		total_weight += final_chances[item]

	var random_value = randf() * total_weight
	cumulative_weight = 0.0
	
	for item in final_chances:
		cumulative_weight += final_chances[item]
		if random_value < cumulative_weight:
			return [item, max(randi_range(entries[item].x, entries[item].y), 1)]

	return []

	