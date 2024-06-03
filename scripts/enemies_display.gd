@tool
extends Control
class_name EnemiesDisplay

@onready var portrait = $avatar_background/avatar_portrait
@onready var description = $enemy_description

signal enemy_group_changed

@export var enemy_name: String = "Mountain Drake":
	set(value):
		enemy_name = value
		update_values()
@export var enemy_class: String = "Rogue":
	set(value):
		enemy_class = value
		update_values()
@export var enemy_level: int = 1:
	set(value):
		enemy_level = value
		update_values()
@export var enemy_portrait: int = 1:
	set(value):
		enemy_portrait = value
		update_values()
@export var enemy_count: int = 2:
	set(value):
		enemy_count = value
		update_values()
		
var enemy_group: EnemyGroup
	
func update_values():
	if Engine.is_editor_hint():
		if description :
			description.text = str(enemy_count) + " " + enemy_name + "\n Lvl : " + str(enemy_level)
			portrait.texture = load("res://assets/ui/fight_ui/enemies/monster_" + "%02d" % enemy_portrait + ".png")
			var enemy_class = EnemyGroup.CLASSES.Warrior if self.enemy_class == "Warrior" else EnemyGroup.CLASSES.Rogue if self.enemy_class == "Rogue" else EnemyGroup.CLASSES.Mage if self.enemy_class == "Mage" else EnemyGroup.CLASSES.None
			enemy_group = EnemyGroup.new(enemy_name, enemy_class, enemy_portrait, enemy_count, enemy_level)
			enemy_group_changed.emit()


func update_group(enemy_group: EnemyGroup):
	self.enemy_group = enemy_group
	description.text = str(enemy_group.enemies_count) + " " + enemy_group.name + "\n Lvl : " + str(enemy_group.level)
	portrait.texture = load("res://assets/ui/fight_ui/enemies/monster_" + "%02d" % enemy_group.enemies_portrait + ".png")
