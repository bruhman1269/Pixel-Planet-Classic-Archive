extends GUIBase


func OnOpen() -> void:
	$Panel/ClaimPlanetButton.disabled = not Global.SelfData.Bits >= 1500


func _on_cancel_button_pressed() -> void:
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Pause)


func _on_claim_planet_button_pressed() -> void:
	Server.WorldClaimRequest()
	Global.WorldNode.WorldGUIManager.CloseGui()
