extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Server.Connect()
	
	while true:
		$Label.text += "."
		
		if $Label.text == "Connecting to Server....":
			$Label.text = "Connecting to Server"
		await get_tree().create_timer(0.7).timeout


func _on_close_button_pressed() -> void:
	get_tree().quit()


func _on_connection_timer_timeout():
	Server.Connect()
	$ConnectionTimer.start(2)
