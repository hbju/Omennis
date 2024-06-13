class_name EnemyGroup

var enemies: Array[Enemy] = []
var enemy_name: String
var enemy_class: Enemy.CLASSES
var enemy_portrait: int
var enemy_level: int

func _init(name, enemies_class, enemies_portrait, enemies_level, enemies_count):
	for i in range(enemies_count):
		enemies.append(Enemy.new(name, enemies_class, enemies_portrait, enemies_level))

	enemy_name = name
	enemy_class = enemies_class
	enemy_portrait = enemies_portrait
	enemy_level = enemies_level
