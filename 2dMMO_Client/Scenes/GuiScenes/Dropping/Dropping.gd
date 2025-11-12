extends GUIBase

var validChars = "0123456789"

var amount_available = 0

func OnOpen():
	$Panel/Amount.clear()
	$ItemFrame/ItemSprite.frame = Global.drop_id + 1
	getMaxAmountID(Global.drop_id)
	$ItemFrame/ItemAmount.text = str(amount_available)
	
	

func getMaxAmountID(_item_id: int) -> void:
	for item in Global.SelfData.Inventory:
		if item[0] == _item_id:
			amount_available = item[1]
			return
			
func _on_amount_text_changed(new_text):
	
	var detected = false
	
	for chr in new_text:
		if not chr in validChars:
			detected = true
	
	if not detected:
		if int(new_text) > 999 or int(new_text) > amount_available or int(new_text) <= 0:
			detected = true
		
		if new_text == "":
			detected = true
		
	if detected:
		$Drop.disabled = true
	else:
		$Drop.disabled = false


func _on_cancel_pressed():
	$Panel/Amount.clear()
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Inventory)


func _on_drop_pressed():
	Server.ItemDropRequest(Global.drop_id, int($Panel/Amount.text))
	Global.WorldNode.WorldGUIManager.CloseGui()


func _on_all_pressed():
	$Panel/Amount.text = str(amount_available)
	$Drop.disabled = false
