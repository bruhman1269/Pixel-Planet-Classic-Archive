extends Sprite2D
@onready var WorldNode = Global.WorldNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(WorldNode):
		self.position.x = clamp(WorldNode.Player.position.x + 32, 1024 / 2, 52 * 32 - 1024/2)
		self.position.y = clamp(WorldNode.Player.position.y, 540 / 2, 1600 - 540 / 2)
