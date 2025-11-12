extends Control

func _ready() -> void:
	Global.EmailPrompt = self
	
	$AnimationPlayer.play("ani")

func _process(delta: float) -> void:
	if len($Panel/LineEdit.text) != 0:
		$Panel/Confirm.disabled = false
	else:
		$Panel/Confirm.disabled = true

func _on_reject_pressed() -> void:
	Server.rpc_id(1, "sendEvent", "rejectEmailPrompt", [])


func _on_confirm_pressed() -> void:
	Server.rpc_id(1, "sendEvent", "confirmEmailPrompt", [$Panel/LineEdit.text])


func close():
	$AnimationPlayer.play_backwards("ani")
	
	await $AnimationPlayer.animation_finished
	queue_free()
