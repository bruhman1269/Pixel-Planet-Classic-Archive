extends Node

var gui_stack: Array[GUIBase] = []
var able_to_change: bool = true
var typing: bool = false


func ConnectViewportStuff(viewport: Viewport) -> void:
	viewport.connect("gui_focus_changed", func(node: Control):
		print("fc")
		if node is LineEdit or node is TextEdit:
			typing = true
		else:
			typing = false
	)
	
	#connect("_process", func(_dt):
		#var current_node := viewport.gui_get_focus_owner()
		#if current_node == null:
			#typing = false
			#return
		#else:
			#if current_node is LineEdit or current_node is TextEdit:
				#typing = true
			#else:
				#typing = false
	#)


func ChangeGui(new_gui: GUIBase, use_background_blur = true) -> void:
	if (new_gui != null and new_gui.can_open == false): return
	
	if (able_to_change == false and new_gui != null): return
	
	for gui in gui_stack:
		if gui.open == true:
			gui.Toggle(use_background_blur)
	
	if new_gui != null:
		
		if len(gui_stack) > 0 and gui_stack.front() == new_gui:
			PlayerState.current_state = PlayerState.STATE_TYPE.WORLD
			gui_stack = []
			return
		
		able_to_change = false
		PlayerState.current_state = PlayerState.STATE_TYPE.GUI
		gui_stack = []
		gui_stack.append(new_gui)
		gui_stack.front().Toggle(use_background_blur)
		await new_gui.opened
		able_to_change = true
		
	else:
		typing = false 
		gui_stack = []
		PlayerState.current_state = PlayerState.STATE_TYPE.WORLD


func PushGui(new_gui: GUIBase) -> void:
	if len(gui_stack) > 0:
		if gui_stack.front().open == true:
			gui_stack.front().Toggle()
 

func PopGui() -> void:
	if gui_stack.front().open == true:
		gui_stack.front().Toggle()


func CloseGui() -> void:
	ChangeGui(null)
