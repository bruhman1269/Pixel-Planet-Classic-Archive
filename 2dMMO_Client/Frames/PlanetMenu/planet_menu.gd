extends GUIBase

func _ready() -> void:
	Global.planetMenu = self
	
	
	$Panel/Movement/MovementOptions/LowGravity.button_pressed = Global.WorldData.LOW_GRAVITY
	
	
	if Global.WorldData.Background == 0:
		$Panel/Visuals/VisualOptions/Overworld.button_pressed = true
	elif Global.WorldData.Background == 1:
		$Panel/Visuals/VisualOptions/Space.button_pressed = true
	elif Global.WorldData.Background == 2:
		$Panel/Visuals/VisualOptions/WinterWonderLand.button_pressed = true
	elif Global.WorldData.Background == 3:
		$Panel/Visuals/VisualOptions/ArcticPlains.button_pressed = true
	elif Global.WorldData.Background == 4:
		$Panel/Visuals/VisualOptions/Desert.button_pressed = true
	
func resetAllVisualOptions():
	for option in $Panel/Visuals/VisualOptions.get_children():
		option.button_pressed = false

func _on_overworld_pressed() -> void:
	resetAllVisualOptions()
	$Panel/Visuals/VisualOptions/Overworld.button_pressed = true
	
	Server.rpc_id(1, "sendEvent", "worldSettingsBackground", [0])


func _on_space_pressed() -> void:
	resetAllVisualOptions()
	$Panel/Visuals/VisualOptions/Space.button_pressed = true
	
	Server.rpc_id(1, "sendEvent", "worldSettingsBackground", [1])

func _on_winter_wonder_land_pressed() -> void:
	resetAllVisualOptions()
	$Panel/Visuals/VisualOptions/WinterWonderLand.button_pressed = true
	
	Server.rpc_id(1, "sendEvent", "worldSettingsBackground", [2])

func _on_arctic_plains_pressed() -> void:
	resetAllVisualOptions()
	$Panel/Visuals/VisualOptions/ArcticPlains.button_pressed = true
	
	Server.rpc_id(1, "sendEvent", "worldSettingsBackground", [3])
func _on_desert_pressed() -> void:
	resetAllVisualOptions()
	$Panel/Visuals/VisualOptions/Desert.button_pressed = true
	
	Server.rpc_id(1, "sendEvent", "worldSettingsBackground", [4])


func _on_low_gravity_pressed() -> void:
	Server.rpc_id(1, "sendEvent", "worldSettingsLowGravity", [])


func _on_close_pressed() -> void:
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Pause)
