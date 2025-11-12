extends StaticBody2D

@onready var collision = $CollisionShape2D
@onready var area = $Area2D

#func _unhandled_input(event: InputEvent) -> void:
#	if event.is_action_pressed("down"):

func disable() -> void:
	area.set_deferred("monitoring", true)




func _on_area_2d_body_entered(body: Node2D) -> void:
	collision.set_deferred("disabled", true)


func _on_area_2d_body_exited(body: Node2D) -> void:
	collision.set_deferred("disabled", false)
	area.set_deferred("monitoring", false)
