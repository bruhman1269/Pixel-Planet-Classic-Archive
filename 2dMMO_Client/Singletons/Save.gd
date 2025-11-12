extends Node




var defaultData = {
	"Settings":{

		"Fullscreen": true,
		"Borderless": false,
		"vSync": true,
		"PeerVolume": 70,
		"GameVolume": 100,
		"MusicVolume": 100,
		
		"DisclaimerAgreement": false,
	},
	
	
	"UserData":{
		"RememberMe": false,
		"Username": "",
		"Password": "",
	},

	"Misc":{
		"FavoritePlanet": "",
		"RecentPlanet": "",
	},
}

var userData = {

}

var path = "user://GameFiles/"
var file_name = "PPclassic.dat"
var password = "AS#$34ou2tF"+ str(OS.get_unique_id()) +"D!#@g67u856;r"

func _ready():
	get_tree().set_auto_accept_quit(false)
	loadFile()
	checkSettings()
	loadSettings()
	
	print(userData)

func _notification(noti):
	if noti == NOTIFICATION_WM_CLOSE_REQUEST:

		saveSettings()

		get_tree().quit()

func loadFile():

	if not FileAccess.file_exists(path + file_name):
		saveFile()

	var file = FileAccess.open_encrypted_with_pass(path + file_name, FileAccess.READ, password)
	userData = JSON.parse_string(file.get_as_text())
	file.close()



func checkSettings():
	var passedCheckWithNoChanges := true
	for item in defaultData.keys():
		for subItem in defaultData[item].keys():
			if not userData[item].has(subItem):
				print(str(item) + " doesn't have: " + str(subItem) + "! Adding variable with default value of: " + str(defaultData[item][subItem]))
				userData[item][subItem] = defaultData[item][subItem]
				passedCheckWithNoChanges = false
	if not passedCheckWithNoChanges:
		print("Did not pass settings variable check, saving new added variables.")
		saveSettings()
	else:
		print("Passed settings variable check, loading settings!")


func loadSettings():
	
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, userData["Settings"]["Borderless"])
	
	if userData.Settings.Fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if userData.Settings.vSync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_volume_db(1, linear_to_db(userData.Settings.GameVolume/100.0))
	AudioServer.set_bus_volume_db(2, linear_to_db(userData.Settings.MusicVolume/100.0))
	AudioServer.set_bus_volume_db(3, linear_to_db(userData.Settings.PeerVolume/100.0))




func saveFile():

	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)

	var file = FileAccess.open_encrypted_with_pass(path + file_name, FileAccess.WRITE, password)
	file.store_line(JSON.stringify(defaultData))
	file.close()

func saveSettings():
	var file = FileAccess.open_encrypted_with_pass(path + file_name, FileAccess.WRITE, password)
	file.store_line(JSON.stringify(userData))
	file.close()
