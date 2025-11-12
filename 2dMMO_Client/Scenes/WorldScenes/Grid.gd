extends Node2D

@onready var grid_sprite = $GridSprite

func _ready() -> void:
	for x in 5:
		for y in 5:
			var new_grid_sprite: Sprite2D = grid_sprite.duplicate()
			new_grid_sprite.visible = false
			new_grid_sprite.name = str(x) + "," + str(y)
			$Sprites.add_child(new_grid_sprite)


func Update(_tile_map: TileMap, _player_pos: Vector2, _mouse_pos: Vector2) -> void:
	
	if not _tile_map: return
	
	for x in 5:
		for y in 5:
			
			var current_grid_sprite: Sprite2D = $Sprites.get_child(x * 5 + y)
			
			var x_pos: int = floor((_player_pos.x + (x - 2) * 32) / 32) * 32 + 16
			var y_pos: int = floor((_player_pos.y + (y - 2) * 32) / 32) * 32 + 16
			var grid_pos: Vector2i = Vector2i(x_pos, y_pos)
			
			var mouse_pos_int = Vector2i(_mouse_pos) / 32 * 32 + Vector2i(16, 16)
			
			current_grid_sprite.position = grid_pos
			
			current_grid_sprite.visible = not (_tile_map.get_cell_tile_data(0, grid_pos / 32) != null)
			
			if PlayerState.current_state == PlayerState.STATE_TYPE.WORLD:
				if Vector2i(current_grid_sprite.position) == mouse_pos_int:
					current_grid_sprite.frame = 1
				else:
					current_grid_sprite.frame = 0


func InRangePlacing(_player_pos: Vector2, _mouse_pos: Vector2) -> bool:
	_player_pos = floor(_player_pos / 32) * 32
	_mouse_pos = floor(_mouse_pos / 32) * 32
	var difference_vector: Vector2i = abs(abs(_player_pos) - abs(_mouse_pos))
	if difference_vector.x <= 64 and difference_vector.y <= 64 and (difference_vector != Vector2i(0, 0)):
		return true
	return false


func InRangeBreaking(_player_pos: Vector2, _mouse_pos: Vector2) -> bool:
	_player_pos = floor(_player_pos / 32) * 32
	_mouse_pos = floor(_mouse_pos / 32) * 32
	var difference_vector: Vector2i = abs(abs(_player_pos) - abs(_mouse_pos))
	if difference_vector.x <= 64 and difference_vector.y <= 64:
		return true
	return false

func Invis() -> void:
	for grid_sprite in $Sprites.get_children():
		grid_sprite.visible = false
