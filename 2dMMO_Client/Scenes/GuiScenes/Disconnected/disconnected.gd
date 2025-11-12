extends CanvasLayer

func _ready():
	Global.DisconnectionNode = self
	self.visible = false


func showDisconnect():
	print("DISCONNECTED")
	self.visible = true
	$AnimationPlayer.play("Fade")
	$BG.play("Fade")
	
	$Timer.start(5)
	
	await $Timer.timeout
	
	if Server.disconnected:
		get_tree().change_scene_to_file("res://Frames/LoadingScreen/loading_screen.tscn")
	
	self.visible = false
