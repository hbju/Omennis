class_name EnemyGroup

var enemies: Array[Character] = []
var enemy: Character

func _init(name, enemies_class, enemies_portrait, enemies_level, enemies_count, enemies_hp=100, enemies_damage=10):
	for i in range(enemies_count):
		enemies.append(Character.new(name, enemies_class, enemies_portrait, enemies_level, enemies_hp, enemies_damage))

	enemy = Character.new(name, enemies_class, enemies_portrait, enemies_level)
