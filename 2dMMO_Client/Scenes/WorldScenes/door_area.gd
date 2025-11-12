extends StaticBody2D

var closed = true

func _process(delta: float) -> void:
	if not closed:
		$CollisionShape2D.disabled = true
	else:
		$CollisionShape2D.disabled = false
