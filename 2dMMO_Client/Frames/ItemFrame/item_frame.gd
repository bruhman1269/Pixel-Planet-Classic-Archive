extends GUIBase

var original_item_id = 0
var mousePos

var new_item_id = 0

func clean():
	$Panel/Panel/ItemButton.modulate = Color(1, 1, 1, 1)
	new_item_id = 0
	$Panel/Panel/ItemSprite.frame = 0

func setup():
	if original_item_id != 0:
		$Panel/Panel/ItemSprite.frame = original_item_id + 1
		$Panel/Panel/ItemButton.modulate = Color(1, 1, 1, 0.078)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if original_item_id != 0:
		$Panel/Remove.disabled = false
	else:
		$Panel/Remove.disabled = true


func _on_item_button_pressed() -> void:
#	Global.WorldNode.prompting_gui = self
	new_item_id = await Global.WorldNode.PromptInventory()
	
	var amount = 1
	
	Global.WorldNode.WorldGUIManager.ChangeGui(self)
	
	$Panel/Panel/ItemSprite.frame = new_item_id + 1
	
	if new_item_id != 0:
		$Panel/Panel/ItemButton.modulate = Color(1, 1, 1, 0.078)
	


func _on_confirm_pressed() -> void:
	Server.SetBlockMetadataRequest(mousePos, {TYPE = "DISPLAY", METADATA = {ITEM_ID = new_item_id}})
	Global.WorldNode.WorldGUIManager.ChangeGui(null)


func _on_remove_pressed() -> void:
	Server.SetBlockMetadataRequest(mousePos, {TYPE = "DISPLAY", METADATA = {ITEM_ID = -1}})
	Global.WorldNode.WorldGUIManager.ChangeGui(null)
