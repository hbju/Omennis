extends Skill
class_name Firespark

var damage := 90
var max_cooldown := 2

const firespark_scene = preload("res://scenes/firespark.tscn")
var caster: CombatCharacter
var target: CombatCharacter
var curr_firespark: FiresparkCombat

func use_skill(from: CombatCharacter, skill_target: CombatCharacter) -> void:
    caster = from
    target = skill_target

    curr_firespark = firespark_scene.instantiate()
    from.get_parent().add_child(curr_firespark)
    curr_firespark.position = from.position
    curr_firespark.move_target = target.position
    curr_firespark.target_reached.connect(_on_reached_target)

    cooldown = max_cooldown
    
func get_skill_name() -> String:
    return "Firespark"

func get_skill_description() -> String:
    return "A basic fire attack that deals 90 damage to a ranged enemy."

func get_skill_icon() -> Texture:
    return load("res://assets/ui/skills/firespark.png")

func get_skill_range() -> int:
    return 4

func target_allies() -> bool:
    return false

func target_enemies() -> bool:
    return true

func target_self() -> bool:
    return false
    
func is_melee() -> bool:
    return false

func _on_reached_target(): 
    target.take_damage(damage)
    curr_firespark.queue_free()
    skill_finished.emit()