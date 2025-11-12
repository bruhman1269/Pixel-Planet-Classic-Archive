extends CanvasLayer

var game_loaded = false



func _process(delta):
	
	await $Loading/AnimationPlayer.animation_finished
	
	if game_loaded:
		$Loading/AnimationPlayer.play("Done")
		await $Loading/AnimationPlayer.animation_finished
		self.queue_free()
