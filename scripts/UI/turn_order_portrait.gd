extends TextureRect # Or TextureRect if no background panel

@onready var portrait_image: TextureRect = $portrait_image
@onready var highlight: ColorRect = $highlight_indicator # Optional

func set_character(character: CombatCharacter, is_current_turn: bool):
	if not character: return
	portrait_image.texture = load(character.character.get_portrait_path())
	if highlight:
		highlight.visible = is_current_turn

func _ready():
	if highlight: highlight.visible = false
