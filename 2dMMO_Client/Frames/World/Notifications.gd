extends Control

@onready var pop_up_scene = load("res://Scenes/GuiScenes/Popup/Popup.tscn")

func _ready():
	Global.NotificationsNode = self

func Notification(message, icon):
	
	var new_popup = pop_up_scene.instantiate()
	
	$VBoxContainer.add_child(new_popup)
	new_popup.InitiatePopUp(message, icon)
