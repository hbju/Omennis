class_name LootTable
extends Resource

@export var entries: Dictionary[BaseItem, Vector3i] = {}

func roll_for_loot() -> Array[BaseItem]:
	var dropped_items: Array[BaseItem] = []
	var roll = randi() % 100
	for entry in entries:
		var drop_info: Vector3i = entries[entry]
		if roll > 0 and roll < drop_info.x:
			var item_count = drop_info.y
			for i in range(item_count):
				dropped_items.append(entry.duplicate())
		roll -= drop_info.x
	return dropped_items