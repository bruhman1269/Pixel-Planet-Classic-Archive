extends Control

@onready var StatusLabel = $StatusLabel
@onready var popup = $Popup

var initpos = null
var total = 0

func _ready() -> void:
	
	Global.AccountMenuNode = self
	initpos = $Title.position
	$Label.text = "Version " + Global.VERSION + "\nOriginal Game by RaoK, Adam, & 8Bit"
	
	if Save.userData.UserData.RememberMe:
		$RememberMe.button_pressed = true
		
		$Credentials/Login/UsernameEdit.text = Save.userData.UserData.Username
		$Credentials/Login/PasswordEdit.text = Save.userData.UserData.Password


func _process(_delta) -> void:
	total += _delta
	$Title.position = initpos + Vector2(0, sin(total / 2) * 10)
	
	if len($Credentials/Login/UsernameEdit.text) > 0 and len($Credentials/Login/PasswordEdit.text) > 0:
		$Credentials/Login/LoginButton.disabled = false
	else:
		$Credentials/Login/LoginButton.disabled = true
	
	if len($Credentials/Create/UsernameEdit.text) > 0 and len($Credentials/Create/PasswordEdit.text) > 0:
		$Credentials/Create/CreateButton.disabled = false
	else:
		$Credentials/Create/CreateButton.disabled = true


func _on_login_button_pressed():
	Login()

func Login():
	Server.loginRequest($Credentials/Login/UsernameEdit.text, $Credentials/Login/PasswordEdit.text)
	
	if not Save.userData.UserData.RememberMe:
		Save.userData.UserData.RememberMe = false
		Save.userData.UserData.Username = ""
		Save.userData.UserData.Password = ""
	else:
		Save.userData.UserData.Username = $Credentials/Login/UsernameEdit.text
		Save.userData.UserData.Password = $Credentials/Login/PasswordEdit.text
	Save.saveSettings()

func _on_create_button_pressed():
	Register()

func Register():
	Server.registerRequest($Credentials/Create/UsernameEdit.text, $Credentials/Create/PasswordEdit.text)
	
	if not Save.userData.UserData.RememberMe:
		Save.userData.UserData.RememberMe = false
		Save.userData.UserData.Username = ""
		Save.userData.UserData.Password = ""
	else:
		Save.userData.UserData.Username = $Credentials/Create/UsernameEdit.text
		Save.userData.UserData.Password = $Credentials/Create/PasswordEdit.text
	Save.saveSettings()

func LoginAfterRegister():
	Server.loginRequest($Credentials/Create/UsernameEdit.text, $Credentials/Create/PasswordEdit.text)
	
	if not Save.userData.UserData.RememberMe:
		Save.userData.UserData.RememberMe = false
		Save.userData.UserData.Username = ""
		Save.userData.UserData.Password = ""
	else:
		Save.userData.UserData.Username = $Credentials/Create/UsernameEdit.text
		Save.userData.UserData.Password = $Credentials/Create/PasswordEdit.text
	Save.saveSettings()
	
func _on_close_button_pressed():
	Save.saveSettings()
	get_tree().quit()

func _on_remember_me_toggled(toggled_on):
	Save.userData.UserData.RememberMe = toggled_on
