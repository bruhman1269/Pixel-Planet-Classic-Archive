extends GUIBase

var item_name: String = ""
var min_price: int = 1
var max_price: int = 999999999


func _process(delta: float) -> void:
	var min_price_edit: int = int($Panel/MinPriceEdit.text)
	var max_price_edit: int = int($Panel/MaxPriceEdit.text)
	
	$Panel/ApplyFiltersButton.disabled = min_price_edit <= 0 or min_price_edit > 999999999 or max_price_edit <= 0 or max_price_edit > 999999999 or min_price_edit > max_price_edit


func _on_reset_filters_button_pressed() -> void:
	item_name = ""
	min_price = 1
	max_price = 999999999
	$Panel/ItemNameEdit.text = ""
	$Panel/MinPriceEdit.text = ""
	$Panel/MaxPriceEdit.text = ""
	
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Marketplace)


func _on_apply_filters_button_pressed() -> void:
	item_name = $Panel/ItemNameEdit.text
	min_price = int($Panel/MinPriceEdit.text)
	max_price = int($Panel/MaxPriceEdit.text)
	
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Marketplace)


func _on_cancel_button_pressed() -> void:
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Marketplace)
