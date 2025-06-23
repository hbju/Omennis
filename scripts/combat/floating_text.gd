extends Label


func _ready():
	# Make the text float upwards and fade out
	var tween = create_tween()
	# Move up
	tween.tween_property(self, "position:y", position.y - 100, 1.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	# Fade out during the last part of the movement
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.5)
	# When the tween is finished, remove the label
	tween.tween_callback(queue_free)

func show_text(text_to_show: String, color: Color = Color.WHITE):
	text = text_to_show
	modulate = color
