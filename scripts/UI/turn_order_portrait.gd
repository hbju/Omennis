extends TextureRect # Or TextureRect if no background panel

@onready var portrait_image: TextureRect = $portrait_image
@onready var highlight: ColorRect = $highlight_indicator # Optional

func set_character(character: CombatCharacter, is_current_turn: bool):
	if not character: return
	portrait_image.texture = load(character.character.get_portrait_path())
	if character is PlayerCombatCharacter : 
		portrait_image.position = Vector2(15,6)
	else : 
		portrait_image.position = Vector2(6,6)
	portrait_image.reset_size()
	portrait_image.size.y = 88
	if highlight:
		highlight.visible = is_current_turn

func _ready():
	if highlight: highlight.visible = false
