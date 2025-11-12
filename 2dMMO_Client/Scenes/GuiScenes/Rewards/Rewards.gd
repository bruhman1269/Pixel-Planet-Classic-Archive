extends GUIBase

@onready var BuyAgainButton = $BuyAgain

var current_pack_id: String

func ShowRewards(items_unpacked):
	print("show rewards")
	$ShowAll.disabled = false
	$BuyAgain.disabled = true
	
	for reward_slot in $HBoxContainer.get_children():
		reward_slot.queue_free()
	
	print(items_unpacked)
	for item in items_unpacked:
		var rewardSlot = load("res://Scenes/GuiScenes/Rewards/RewardSlot.tscn").instantiate()
		rewardSlot.setup(item[0], item[1])
		
		$HBoxContainer.add_child(rewardSlot)
	

func updateButtons():
	var all_slots_are_visible = true
	for reward_slot in $HBoxContainer.get_children():
		if not reward_slot.open:
			all_slots_are_visible = false
	
	
	$BuyAgain.disabled = !all_slots_are_visible
	
	if all_slots_are_visible:
		$ShowAll.disabled = true
	print(!all_slots_are_visible)
	

func _on_show_all_pressed() -> void:
	for reward_slot in $HBoxContainer.get_children():
		reward_slot.Reveal()
	$ShowAll.disabled = true


func _on_close_pressed() -> void:
	Global.WorldNode.WorldGUIManager.CloseGui()


func _on_buy_again_pressed() -> void:
	Global.WorldNode.WorldGUIManager.CloseGui()
	Server.ShopPurchaseRequest(Global.WorldNode.Rewards.current_pack_id)
