extends Control
class_name PartyUI

@onready var displays: Array[CharacterDisplay] = [$bg/displays/main_character_display, 
	$bg/displays/character_display2, 
	$bg/displays/character_display3, 
	$bg/displays/character_display4]

@onready var character_sheet: Control = $character_sheet_ui
	
signal fire_character(index)
	
const PARTY_MAX_NUMBER = 4

func _ready() : 
	for i in range(0, PARTY_MAX_NUMBER) :
		displays[i].fire_character.connect(_on_fire_character.bind(i))
		displays[i].show_skill_tree.connect(_on_show_character_sheet.bind(i))

# Called when the node enters the scene tree for the first time.
func update_ui(party: Array[PartyMember]) :
	character_sheet.hide()
	for i in range(0, party.size()):
		displays[i].update_character(party[i])
		displays[i].visible = true
	for i in range(party.size(), PARTY_MAX_NUMBER) :
		displays[i].visible = false
		
func _on_fire_character(index: int) : 
	fire_character.emit(index)

func _on_show_character_sheet(index: int) : 
	character_sheet.show_sheet(displays[index].party_member)
