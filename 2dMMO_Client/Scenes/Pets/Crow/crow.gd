extends AnimatedSprite2D

# Variables
var offset_distance = 20  # Distance from the player
var orbit_speed = 2.0      # Speed of the crow's rotation around the player
var angle = 0.0            # Current angle for the crow's orbit


func _process(delta):
	if is_instance_valid(Global.PlayerNode):
		# Increase the angle over time to make the crow orbit
		angle += orbit_speed * delta

		# Calculate the crow's position in polar coordinates
		var x_offset = offset_distance * cos(angle)
		var y_offset = offset_distance * sin(angle)

		# Set the crow's position relative to the player's position
		self.position = Global.PlayerNode.position + Vector2(x_offset, y_offset)
