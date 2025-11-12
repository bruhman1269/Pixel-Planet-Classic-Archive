extends Control




func _on_quit_button_pressed() -> void:
	Save.saveSettings()
	get_tree().quit()
