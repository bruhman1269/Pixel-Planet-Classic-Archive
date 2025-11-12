extends GUIBase


var item1_id: int = -1
var item2_id: int = -1

var item1_amount: int = 0
var item2_amount: int = 0

var currently_crafting: bool = false


func update_slots() -> void:
	$Panel/Item1Sprite.frame = item1_id + 1
	$Panel/Item2Sprite.frame = item2_id + 1
	
	$Panel/Item1Amount.text = str(item1_amount)
	$Panel/Item2Amount.text = str(item2_amount)
	
	if item1_amount <= 0:
		$Panel/Item1Amount.text = ""
		$Panel/Item1Amount.text = ""
	if item2_amount <= 0:
		$Panel/Item2Amount.text = ""
		$Panel/Item2Amount.text = ""
	
	var recipe_result = Data.GetRecipe(item1_id, item2_id, item1_amount, item2_amount)
	if recipe_result == {}: return
	
	$Panel/ResultItemSprite.frame = recipe_result.RESULT[0] + 1
	$Panel/ResultAmount.text = str(recipe_result.RESULT[1] * recipe_result.AMOUNT)
	
	if item1_amount >= recipe_result.INGREDIENT_1[1] and item2_amount >= recipe_result.INGREDIENT_2[1] and recipe_result.AMOUNT > 0:
		$Panel/CraftButton.disabled = false
		$Panel/NotEnoughLabel.visible = false
	else:
		$Panel/CraftButton.disabled = true
		$Panel/NotEnoughLabel.visible = true


func OnOpen():
	$Panel/CraftButton.disabled = true
	$Panel/ResultItemSprite.frame = 0
	$Panel/ResultAmount.text = ""
	$Panel/NotEnoughLabel.visible = false


func _on_item_1_button_pressed() -> void:
	
	Global.WorldNode.prompting_gui = self
	var item_id: int = await Global.WorldNode.PromptInventory()
	self.item1_id = item_id
	
	if self.item1_id == self.item2_id:
		self.item1_id = -1
	
	var amount: int = await Global.WorldNode.PromptItemAdder()
	self.item1_amount = amount
	
	if amount == 0:
		self.item1_id = -1
		self.item1_amount = 0
	
	Global.WorldNode.WorldGUIManager.ChangeGui(self)
	self.update_slots()


func _on_item_2_button_pressed() -> void:
	
	Global.WorldNode.prompting_gui = self
	var item_id: int = await Global.WorldNode.PromptInventory()
	self.item2_id = item_id
	var amount: int = await Global.WorldNode.PromptItemAdder()
	self.item2_amount = amount
	
	if self.item1_id == self.item2_id:
		self.item2_id = -1
		self.item2_amount = 0
	
	if amount == 0:
		self.item2_id = -1
		
	Global.WorldNode.WorldGUIManager.ChangeGui(self)
	self.update_slots()


func _on_cancel_button_pressed() -> void:
	Global.WorldNode.WorldGUIManager.CloseGui()



func _on_craft_button_pressed() -> void:
	Server.CraftRequest(self.item1_id, self.item2_id, self.item1_amount, self.item2_amount)
	Global.WorldNode.WorldGUIManager.CloseGui()
