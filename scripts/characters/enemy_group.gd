class_name EnemyGroup

var enemies: Array[Character] = []
var enemy: Character

func _init(name, enemies_class, enemies_portrait, enemies_level, enemies_count):
	for i in range(enemies_count):
		enemies.append(Character.new(name, enemies_class, enemies_portrait, enemies_level))

	enemy = Character.new(name, enemies_class, enemies_portrait, enemies_level)
