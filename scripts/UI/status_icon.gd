extends TextureRect

@onready var duration_label: Label = $duration_label
@onready var level_label: Label = $level_label # If you added a label

func _ready():
	print("StatusIcon ready")
	# Hide labels by default
	duration_label.hide()
	level_label.hide()

func set_data(icon_texture: Texture, duration: int = -1, level: int = -1) -> void:
	print("Setting data for status icon")
	print("Icon texture: ", icon_texture)
	print("Duration: ", duration)
	print("Level: ", level)
	texture = icon_texture
	if duration > 0:
		duration_label.text = str(duration)
		duration_label.show()
	else:
		duration_label.text = ""
		duration_label.hide()
	
	print("Level: ", level)
	if level > 0:
		level_label.text = str(level)
		level_label.show()
	else:
		level_label.text = ""
		level_label.hide()
