class_name EnemyGroup

var enemies: Array[Character] = []
var enemy: Character

func _init(name, enemies_class, enemies_portrait, enemies_level, enemies_count, enemies_hp=100, enemies_damage=10):
	for i in range(enemies_count):
		enemies.append(Character.new(name, enemies_class, enemies_portrait, enemies_level, enemies_hp, enemies_damage))

	enemy = Character.new(name, enemies_class, enemies_portrait, enemies_level)

static func from_enemy_data(archetype: String, level: int, count: int, name: String = "", enemy_portrait: int = -1) -> EnemyGroup:
	var class_data = EnemyData.ENEMY_CLASS_DEFINITIONS[archetype]

	var max_hp = class_data.base_hp + (level - 1) * class_data.hp_per_level
	var damage_stat = class_data.base_damage_stat + (level - 1) * class_data.damage_stat_per_level

	var enemy_name = name if name != "" else archetype # Simple name
	var portrait_idx = enemy_portrait if enemy_portrait != -1 else class_data.portraits[randi() % class_data.portraits.size()]
	
	var group = EnemyGroup.new(
		enemy_name,
		class_data.class_enum, 
		portrait_idx,
		level,
		count,
		max_hp,
		damage_stat
	)

	for skill_entry in class_data.skill_pool_config:
		if level >= skill_entry.min_level:
			for e in group.enemies:
				e.skill_list.append(skill_entry.skill.new())

	return group