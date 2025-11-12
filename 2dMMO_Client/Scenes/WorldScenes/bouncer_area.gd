extends StaticBody2D

var bounce = false

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("BounceCollider") and area.get_parent() == Global.PlayerNode:
		bounce = true


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("BounceCollider") and area.get_parent() == Global.PlayerNode:
		bounce = false

func _process(delta: float) -> void:
	if bounce:
		Global.PlayerNode.bounce(300, position)
