class_name Array2D

var x_size: int
var y_size: int
var array: Array


func _init(x_size: int, y_size: int) -> void:
	self.x_size = x_size
	self.y_size = y_size


func fill(item) -> void:
	self.array = []
	
	for i in self.x_size * self.y_size:
		self.array[i] = item


func get_item(x: int, y: int):
	return self.array[x + y * x_size]


func set_item(x: int, y: int, item) -> void:
	self.array[x + y * x_size] = item
