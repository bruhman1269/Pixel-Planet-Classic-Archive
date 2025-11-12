extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.get_connected_joypads().has(0) and (abs(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)) >= 0.1 or abs(Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)) >= 0.1):
		var NewMousePosition: Vector2 = get_viewport().get_mouse_position() + Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)) * 3.7
		get_viewport().warp_mouse(NewMousePosition)
