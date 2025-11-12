extends GUIBase

@onready var label = $Panel/Label

var text: String  = ""

signal prompt_finished

func setText(_text):
	$Panel/Amount.text = _text

func OnOpen():
	$Panel/NextButton.disabled = true
	$Panel/Amount.text = ""


func _on_cancel_button_pressed() -> void:
	self.text = ""
	emit_signal("prompt_finished")


func _on_next_button_pressed() -> void:
	self.text = $Panel/Amount.text
	emit_signal("prompt_finished")


func _on_amount_text_changed(new_text: String) -> void:
	$Panel/NextButton.disabled = $Panel/Amount.text == ""
