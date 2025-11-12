extends Sprite2D

@export var frame_duration: float = 0.05

var time_since_last_frame: float = 0.0


var max_frames

func _process(delta: float) -> void:
	time_since_last_frame += delta
	
	if time_since_last_frame >= frame_duration:
		frame += 1
	
		if frame == max_frames:
			queue_free()
		
		time_since_last_frame = 0.0
