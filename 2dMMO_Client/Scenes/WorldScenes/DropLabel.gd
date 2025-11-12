extends Label


func _process(dt):
	self.set("theme_override_colors/font_color", self.get("theme_override_colors/font_color") - Color(0, 0, 0, 0.7 * dt))
	self.position -= Vector2(0, 15 * dt)

func Summon(item_id, amount, breaker: CharacterBody2D):
	
	# Set position
	self.set("theme_override_colors/font_color", Color.WHITE)
	print(self.size.x)
	self.position = breaker.position - Vector2(self.size.x / 2, 42)

	# Get item name
	var item_name: String
	if item_id == -100:
		item_name = "bits"
	else:
		item_name = Data.ItemData[str(item_id)].NAME
	
	# Set label
	var text_label = str(amount) + "x " + item_name
	self.text = text_label
	
	# DESTROY after a second
	await get_tree().create_timer(1.4).timeout
	self.queue_free()
