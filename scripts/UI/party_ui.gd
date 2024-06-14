extends Control
class_name PartyUI

@onready var displays: Array[Character_Display] = [$bg/displays/main_character_display, 
	$bg/displays/character_display2, 
	$bg/displays/character_display3, 
	$bg/displays/character_display4]
	
signal fire_character(index)
	
const PARTY_MAX_NUMBER = 4

func _ready() : 
	displays[1].fire_character.connect(_on_fire_character.bind(1))
	displays[2].fire_character.connect(_on_fire_character.bind(2))
	displays[3].fire_character.connect(_on_fire_character.bind(3))

# Called when the node enters the scene tree for the first time.
func update_ui(party: Array[PartyMember]) :
	for i in range(0, party.size()):
		displays[i].update_character(party[i])
		displays[i].visible = true
	for i in range(party.size(), PARTY_MAX_NUMBER) :
		displays[i].visible = false
		
func _on_fire_character(index: int) : 
	fire_character.emit(index)
