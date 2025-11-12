extends GUIBase

var amount: int

signal prompt_finished


func OnOpen():
	$Panel/NextButton.disabled = true
	$Panel/Amount.text = ""
	$Panel/Label.text = "How many items would you like to add?\nYou have " + str(Global.WorldNode.Inventory.current_item_amount) + "."


func _on_cancel_button_pressed() -> void:
	self.amount = 0
	emit_signal("prompt_finished")


func _on_next_button_pressed() -> void:
	self.amount = int($Panel/Amount.text)
	emit_signal("prompt_finished")


func _on_amount_text_changed(new_text: String) -> void:
	$Panel/NextButton.disabled = not (int($Panel/Amount.text) > 0 and int($Panel/Amount.text) <= Global.WorldNode.Inventory.current_item_amount)
