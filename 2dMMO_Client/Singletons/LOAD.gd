extends Node

@onready var MouseImage = preload("res://Assets/Gui/Mouse/image.png")
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_custom_mouse_cursor(MouseImage)
