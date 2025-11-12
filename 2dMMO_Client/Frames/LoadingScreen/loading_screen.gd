extends Control


@onready var disclaimer: PackedScene = load("res://Frames/Disclaimer/Disclaimer.tscn")

var loadWaitTime := 2.0



#Node Imports
@onready var timer = $Timer



func _ready():
	if not Save.userData["Settings"]["DisclaimerAgreement"]:
		get_tree().change_scene_to_packed(disclaimer)
	
	timer.start(loadWaitTime)



func _on_timer_timeout():
	Server.Connect()
	
	timer.start(loadWaitTime)


func _on_close_pressed():
	get_tree().quit()
