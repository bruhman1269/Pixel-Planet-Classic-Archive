extends Control

@onready var loading_screen: PackedScene = load("res://Frames/LoadingScreen/loading_screen.tscn")

func _on_close_button_pressed():
	get_tree().quit()


func _on_disclaimer_timer_timeout():
	$AgreeButton.disabled = false


func _on_agree_button_pressed():
	Save.userData["Settings"]["DisclaimerAgreement"] = true
	get_tree().change_scene_to_packed(loading_screen)
