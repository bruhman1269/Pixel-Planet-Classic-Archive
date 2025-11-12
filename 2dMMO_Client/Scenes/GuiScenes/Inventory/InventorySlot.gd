extends Button

var item_id: int = -1
var amount: int = 0

var item_data = {}

var hovered: bool = false
var pressed_down: bool = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		
		if self.item_id == -1: return
		if self.amount < 0: return
		
		Global.InventoryNode.current_item = self.item_id
		Global.InventoryNode.current_item_amount = self.amount
		
		var item_data = Data.ItemData[str(self.item_id)]
		var last_slot = Global.InventoryNode.last_selected_inventory_slot
		
		if Global.WorldNode.Inventory.prompting == true:
			if not (item_data.has("UNSELLABLE") and item_data.UNSELLABLE == true):
				Global.WorldNode.Inventory.emit_signal("prompt_finished")
			
		$SelectSprite.visible = true
		
		if last_slot and last_slot != self:
			last_slot.get_node("SelectSprite").visible = false
			#last_slot.get_node("CheckmarkSprite").visible = false
		
		if event.double_click and item_data.TYPE == "CLOTHING" and Global.WorldNode.Inventory.prompting == false:
			Server.EquipClothingRequest(self.item_id)
		
		Global.InventoryNode.last_selected_inventory_slot = self


func Update() -> void:
	$ItemPicture.frame = item_id + 1
	
	if amount > 1:
		$AmountLabel.text = str(amount)
		$AmountLabelBackground.text = str(amount)
	else:
		$AmountLabel.text = ""
		$AmountLabelBackground.text = ""
	
	if amount <= 0:
		Global.InventoryNode.AddSlot()
		
		if Global.InventoryNode.last_selected_inventory_slot == self:
			Global.InventoryNode.last_selected_inventory_slot = null
			Global.InventoryNode.current_item = 0
			
			if Data.ItemData[str(self.item_id)].TYPE == "BLOCK" or Data.ItemData[str(self.item_id)].TYPE == "BACKGROUND":
				Global.WorldNode.should_update_grid = false
				Global.WorldNode.WorldBlockManager.last_pressed = Time.get_ticks_usec()
		
		self.queue_free()

func Checkmark(_on_or_off: bool) -> void:
	$CheckmarkSprite.visible = _on_or_off


func _on_mouse_entered():
	if item_id == -1: return
	if item_data.has("UNSELLABLE") and item_data.UNSELLABLE == true: return
	
	hovered = true
	
	if pressed_down:
		Global.InventoryNode.dragging = true
		Global.InventoryNode.dragging_id = item_id
		Global.InventoryNode.drag_animation.play("Fade")
	else:
		Global.InventoryNode.in_drop_zone = false


func _on_mouse_exited():
	if item_id == -1: return
	if item_data.has("UNSELLABLE") and item_data.UNSELLABLE == true: return
	
	if pressed_down:
		Global.InventoryNode.dragging = true
		Global.InventoryNode.dragging_id = item_id
		Global.InventoryNode.drag_animation.play("Scale")
		Global.InventoryNode.in_drop_zone = true

func _on_button_up():
	if item_id == -1: return
	if item_data.has("UNSELLABLE") and item_data.UNSELLABLE == true: return
	
	pressed_down = false
	
	if not Global.InventoryNode.isAreaVisible():
		Global.InventoryNode.dragging = false
		Global.InventoryNode.dragging_id = -1
		Global.InventoryNode.drag_animation.play("Fade")
	
	if not Global.InventoryNode.in_drop_zone:
		Global.InventoryNode.dragging = false
		Global.InventoryNode.dragging_id = -1
		Global.InventoryNode.drag_animation.play("Fade")
	else:
		Global.drop_id = item_id
		Global.InventoryNode.drag_animation.play("Fade")
		Global.InventoryNode.dragging = false
		Global.InventoryNode.dragging_id = -1
		Global.InventoryNode.in_drop_zone = false
		
		
		hovered = false
		Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Dropping)
		Global.InventoryNode.DropAreaVisible(false)


func _on_button_down():
	if item_id == -1: return
	if item_data.has("UNSELLABLE") and item_data.UNSELLABLE == true: return
	$Click.play()
	pressed_down = true
