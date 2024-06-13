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
			var _class = Enemy.CLASSES.Warrior if self.enemy_class == "Warrior" else Enemy.CLASSES.Rogue if self.enemy_class == "Rogue" else Enemy.CLASSES.Mage if self.enemy_class == "Mage" else Enemy.CLASSES.None
			enemy_group = EnemyGroup.new(enemy_name, _class, enemy_portrait, enemy_count, enemy_level)
			enemy_group_changed.emit()


func update_group(new_group: EnemyGroup):
	self.enemy_group = new_group
	description.text = str(new_group.enemies.size()) + " " + new_group.enemy_name + "\n Lvl : " + str(new_group.enemy_level)
	portrait.texture = load("res://assets/ui/fight_ui/enemies/monster_" + "%02d" % new_group.enemy_portrait + ".png")
