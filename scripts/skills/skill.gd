class_name Skill

var skill_name: String
var skill_icon: Texture
var skill_range: float

func _init(name: String, icon: Texture, _range: float):
    self.skill_name = name
    self.skill_icon = icon
    self.skill_range = _range

func use_skill(_target: Node):
    # Add your skill logic here
    pass