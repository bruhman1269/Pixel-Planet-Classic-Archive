extends GUIBase

var item_id: int = -1
var item_amount: int = 0

var currently_crafting: bool = false


func update_slots() -> void:
	$Panel/ItemSprite.frame = item_id + 1
	
	$Panel/ItemAmount.text = str(item_amount)
	
	if item_amount <= 0:
		$Panel/ItemAmount.text = ""

	
	var recipe_result = Data.GetGrind(item_id, item_amount)
	if recipe_result == {}: return
	
	$Panel/ResultItemSprite.frame = recipe_result.RESULT[0] + 1
	$Panel/ResultAmount.text = str(recipe_result.RESULT[1] * recipe_result.AMOUNT)
	
	if recipe_result.AMOUNT >= 0:
		$Panel/GrindButton.disabled = false
		$Panel/NotEnoughLabel.visible = false
	else:
		$Panel/GrindButton.disabled = true
		$Panel/NotEnoughLabel.visible = true


func OnOpen():
	$Panel/ItemButton.set_modulate(Color(1, 1, 1, 1))
	$Panel/GrindButton.disabled = true
	$Panel/ResultItemSprite.frame = 0
	$Panel/ResultAmount.text = ""
	$Panel/NotEnoughLabel.visible = false


func _on_cancel_button_pressed() -> void:
	Global.WorldNode.WorldGUIManager.CloseGui()


func _on_craft_button_pressed() -> void:
	Server.GrindRequest(self.item_id, self.item_amount)
	Global.WorldNode.WorldGUIManager.CloseGui()


func _on_item_button_pressed() -> void:
	
	Global.WorldNode.prompting_gui = self
	var temp_item_id: int = await Global.WorldNode.PromptInventory()
	self.item_id = temp_item_id
	var amount: int = await Global.WorldNode.PromptItemAdder()
	Global.WorldNode.WorldGUIManager.ChangeGui(self)
	self.item_amount = amount
	
	if amount == 0:
		self.item_id = -1
		
	#Global.WorldNode.WorldGUIManager.CloseGui()
	self.update_slots()

func _process(delta):
	if item_id != -1:
		$Panel/ItemButton.set_modulate(Color(1, 1, 1, 0))
