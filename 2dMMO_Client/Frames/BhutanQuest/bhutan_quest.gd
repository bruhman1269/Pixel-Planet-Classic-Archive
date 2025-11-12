extends GUIBase

func requestCurrentStatus():
	Server.rpc_id(1, "sendEvent", "requestBhutanQuestStatus", [])

func returnStatus(info):
	
	$CurrentStep.text = "Current Step: %s/%s" % [info["current_step"], info["max_steps"]]
	
	$Objective.text = info["steps"][str(info["current_step"])]["objective"] % [info["steps"][str(info["current_step"])]["CURRENT_AMOUNT"]]
	$Description.text = info["steps"][str(info["current_step"])]["description"]
	
	print(info["steps"][str(info["current_step"])]["AMOUNT"])
	
	$ProgressBar.value = (float(info["steps"][str(info["current_step"])]["CURRENT_AMOUNT"]) / float(info["steps"][str(info["current_step"])]["AMOUNT"])) * 100.0
	
	if info["completed"] && not info["collected"]:
		$Panel/Collect.disabled = false
	else:
		$Panel/Collect.disabled = true
	
	if info["collected"]:
		$Reward.visible = false
		$Panel/Collect.visible = false
		$Panel/Close.position.x = 194
		$CurrentStep.text = "Quest has been completed!"
		
		$ProgressBar.visible = false
		$Objective.visible = false
		$Description.visible = false
		
		$Finished.visible = true
		$Panel/Close.text = "Thank you :'("
		
func _on_close_pressed() -> void:
	Global.WorldNode.WorldGUIManager.ChangeGui(null)


func _on_collect_pressed() -> void:
	Server.rpc_id(1, "sendEvent", "collectBhutanQuestReward", [])
	Global.WorldNode.WorldGUIManager.ChangeGui(null)
