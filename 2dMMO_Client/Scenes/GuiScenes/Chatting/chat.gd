extends GUIBase

var valid_characters = r" `~abcdefghijklmnopqrstuvwxyz0123456789)!@#$%^&*(-=_+\|[]{};:,<.>/?'\""

func _ready():
	Global.ChatNode = self

func incomingMessage(nickname, message):
	$Messages.text += "\n" + "<" + nickname + "> " + message

func _process(delta):
	AutoScroll()

func AutoScroll():
	var max_value = $Messages.get_v_scroll_bar().max_value

	var scroll_position = max_value - $Messages.get_v_scroll_bar().value
	var rect_height = $Messages.size.y
	
	if round(scroll_position) == round(rect_height) or round(max_value) <= round(rect_height):
		$Messages.scroll_following = true
	else:
		$Messages.scroll_following = false

func _input(event):
	if Input.is_action_just_pressed("Chat"):
		if not $ChatInput.has_focus():
			$ChatInput.grab_focus()
			
		if $ChatInput.has_focus() and len($ChatInput.text) != 0:
			
			var text = cleanText($ChatInput.text)
			
			if len(text) != 0:
				Server.rpc_id(1, "sendEvent", "messageRequest", [text])
				Global.WorldNode.WorldGUIManager.CloseGui()
			
			$ChatInput.release_focus()
			$ChatInput.clear()
	
func cleanText(text):
	
	var new_string = ""

	for chr in text:
		if not chr.to_lower() in valid_characters:
			continue
		else:
			new_string += chr
	
	return new_string

func OnClose() -> void:
	$ChatInput.release_focus()
	$Messages.scroll_following = true
	Global.WorldNode.WorldGUIManager.typing = false
