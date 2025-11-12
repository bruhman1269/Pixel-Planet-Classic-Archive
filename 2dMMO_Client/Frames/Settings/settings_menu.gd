extends GUIBase

var Forest = preload("res://Assets/Audio/Music/lakeside-trees.ogg") # ID 0
var Space = preload("res://Assets/Audio/spacebackground.ogg") # ID 1
var WinterWonderland = preload("res://Assets/Audio/winterwonderland.ogg") # ID 2
var ArcticPlains = preload("res://Assets/Audio/arcticplains.ogg") # ID 3

#Node Imports
@onready var fullscreenButton = %FullscreenButton
@onready var vsyncButton = %VsyncButton
@onready var volumeSlider = %VolumeSlider
@onready var musicSlider = %MusicSlider
@onready var closeButton = %CloseButton
@onready var muteNetworkButton = %MuteNetworkButton
@onready var peerVolumeSlider = %PeerVolumeSlider
@onready var borderlessButton = %BorderlessButton


func change_sound(id):
	if id == 0:
		$AudioStreamPlayer.stream = Forest
	elif id == 1:
		$AudioStreamPlayer.stream = Space
	elif id == 2:
		$AudioStreamPlayer.stream = WinterWonderland
	elif id == 3:
		$AudioStreamPlayer.stream = ArcticPlains
	else:
		$AudioStreamPlayer.stream = WinterWonderland
	
	$AudioStreamPlayer.play()

func _ready():
	OnOpen()



func OnOpen():
	if Save.userData.Settings.Fullscreen:
		fullscreenButton.button_pressed = true
	if Save.userData.Settings.vSync:
		vsyncButton.button_pressed = true
	if Save.userData.Settings.Borderless:
		borderlessButton.button_pressed = true
	volumeSlider.value = Save.userData.Settings.GameVolume
	musicSlider.value = Save.userData.Settings.MusicVolume
	peerVolumeSlider.value = Save.userData.Settings.PeerVolume



func _on_fullscreen_button_pressed():
	Save.userData.Settings.Fullscreen = fullscreenButton.button_pressed
	Save.loadSettings()



func _on_vsync_button_pressed():
	Save.userData.Settings.vSync = vsyncButton.button_pressed
	Save.loadSettings()



func _on_close_button_pressed():
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Pause)



func _on_volume_slider_drag_ended(value_changed):
	if value_changed:
		Save.userData.Settings.GameVolume = volumeSlider.value
		Save.loadSettings()



func _on_music_slider_drag_ended(value_changed):
	if value_changed:
		Save.userData.Settings.MusicVolume = musicSlider.value
		Save.loadSettings()



func _on_peer_slider_drag_ended(value_changed):
	if value_changed:
		Save.userData.Settings.PeerVolume = peerVolumeSlider.value
		Save.loadSettings()




func _on_borderless_button_pressed():
	Save.userData.Settings.Borderless = borderlessButton.button_pressed
	Save.loadSettings()
