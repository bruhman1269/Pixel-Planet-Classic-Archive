extends Control

@onready var promoted_planet_button = $Tabs/PlanetTab/PromotedPlanetButton
@onready var recent_planet_button = $Tabs/PlanetTab/RecentPlanetButton
@onready var favorite_planet_button = $Tabs/PlanetTab/FavoritePlanetButton
@onready var login_status_label = $LoginStatusLabel
@onready var label_2 = $Label2
@onready var world_name_edit = $Tabs/PlanetTab/WorldNameEdit
@onready var planet_tab = $Tabs/PlanetTab
@onready var settings_tab = $Tabs/SettingsTab
@onready var popup := $Popup

func _ready():
	
	Global.worldMenu = self
	
	Server.rpc_id(1, "sendEvent", "loadedWorldMenu", [])
	
	login_status_label.text = "Logged in as: " + Global.Username
	label_2.text = "Version " + Global.VERSION + "\nOriginal Game by RaoK, Adam, & 8Bit"
	if Global.LastVisitedPlanet != "":
		recent_planet_button.disabled = false
		recent_planet_button.text = "Recent Planet: " + Global.LastVisitedPlanet.to_upper()
	if Save.userData.Misc.FavoritePlanet != "":
		favorite_planet_button.disabled = false
		favorite_planet_button.text = "Favorite Planet: " + Save.userData.Misc.FavoritePlanet.to_upper()
	
	Server.rpc_id(1, "sendEvent", "requestPromotedPlanet", [])

#func _on_enter_world_button_pressed():
	#Server.worldJoinRequest(world_name_edit.text)


func _on_recent_planet_button_pressed() -> void:
	Server.worldJoinRequest(Global.LastVisitedPlanet)



func _on_favorite_planet_button_pressed():
	Server.worldJoinRequest(Save.userData.Misc.FavoritePlanet)



func _on_hub_button_pressed() -> void:
	Server.worldJoinRequest("hub")



func _on_world_name_edit_text_changed(new_text: String) -> void:
	$Tabs/PlanetTab/EnterWorldButton2.disabled = not len(new_text) > 0

func _on_planets_button_pressed():
	resetUI()
	planet_tab.visible = true

func _on_settings_button_pressed():
	resetUI()
	settings_tab.visible = true

func promptEmail():
	var emailPromptNode = load("res://Frames/EmailPrompt/email_prompt.tscn").instantiate()
	
	$CanvasLayer.add_child(emailPromptNode)
	$CanvasLayer.move_child(emailPromptNode, 0)

func resetUI():
	for tab in $Tabs.get_children():
		tab.visible = false





func _on_fullscreen_toggle_toggled(toggled_on):

	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		Save.userData.Settings.Fullscreen = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)




func _on_enter_world_button_2_pressed() -> void:
	Server.worldJoinRequest(world_name_edit.text)



func _on_audio_stream_player_finished() -> void:
	$AudioStreamPlayer.play()


func _on_dive_in_button_pressed():
	Server.rpc_id(1, "sendEvent", "worldDiveInRequest", [])


func _on_promoted_planet_button_pressed() -> void:
	Server.worldJoinRequest(promoted_planet_button.text)


func _on_bhutans_mountain_button_pressed() -> void:
	Server.worldJoinRequest("Bhutan")
