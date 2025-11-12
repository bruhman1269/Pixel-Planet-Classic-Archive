extends Sprite2D

var peer_breaking = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	$AnimationPlayer.play("smoke")


func ShouldBreak(b: bool) -> void:
	
	if peer_breaking:
		if b:
			$Peer/breakstream2.pitch_scale += randf_range(-0.2, 0.2)
			$Peer/breakstream2.play()
		else:
			$Peer/placestream2.pitch_scale += randf_range(-0.2, 0.2)
			$Peer/placestream2.play()
	
	else:
		if b:
			$Client/breakstream.pitch_scale += randf_range(-0.2, 0.2)
			$Client/breakstream.play()
		else:
			$Client/placestream.pitch_scale += randf_range(-0.2, 0.2)
			$Client/placestream.play()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	self.queue_free()
