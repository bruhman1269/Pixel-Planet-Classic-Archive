extends Control

func _ready():
	$AnimationPlayer.play("Appear")
	$SFX.play()

func InitiatePopUp(message, icon):
	$NotificationBG/NotificationLabel.text = message
	$NotificationBG/NotificationIcon.frame = icon

func _on_timer_timeout():
	$AnimationPlayer.play("Disappear")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Disappear":
		queue_free()
