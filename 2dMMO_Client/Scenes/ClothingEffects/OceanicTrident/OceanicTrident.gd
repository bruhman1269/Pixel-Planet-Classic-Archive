extends Sprite2D

@onready var destination
@onready var _ready: bool = false

func _process(delta):
	if ready:
		
		self.position = self.position.move_toward(destination, 0.2)
		
		
		if destination.distance_to(self.position) <= 3:
			print("done, close")
			self.queue_free()
	
