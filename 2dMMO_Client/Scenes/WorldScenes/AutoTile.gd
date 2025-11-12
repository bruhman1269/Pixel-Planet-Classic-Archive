extends TileMap
const GRASS_BLOCK = 0


const SIXTEEN_TILES: Array = [
	Vector2i(2,1), #0
	Vector2i(1,1), #1
	Vector2i(2,2), #2
	Vector2i(1,2), #3
	Vector2i(3,1), #4
	Vector2i(0,1), #5
	Vector2i(3,2), #6
	Vector2i(0,2), #7
	Vector2i(2,0), #8
	Vector2i(1,0), #9
	Vector2i(2,3), #10
	Vector2i(1,3), #11
	Vector2i(3,0), #12
	Vector2i(0,0), #13
	Vector2i(3,3), #14
	Vector2i(0,3), #15
]

const SIXTEEN_TILES_SPECIAL: Dictionary = {
	"104" = Vector2i(4,0),
	"240" = Vector2i(4,1),
	"146" = Vector2i(4,2)
}


func Autotile2(tilesetId: int, _position: Vector2i) -> void:
	var CurrentTile: int = self.get_cell_source_id(0, _position)
	var UpperTile: int = self.get_cell_source_id(0, _position - Vector2i(0, 1))
	var LowerTile: int = self.get_cell_source_id(0, _position + Vector2i(0, 1))
	
	if UpperTile == tilesetId and CurrentTile == tilesetId:
		self.set_cell(0, _position, CurrentTile, Vector2i(0, 1))
	
	if LowerTile == tilesetId:
		if CurrentTile == tilesetId:
			set_cell(0, _position + Vector2i(0, 1), tilesetId, Vector2i(0, 1))
		else:
			set_cell(0, _position + Vector2i(0, 1), tilesetId, Vector2i(0, 0))


func Autotile4(tilesetId: int, _position: Vector2i, _autotile_surroundings: bool, _block_type: String) -> void:
	var item = Data.ItemFromTilesetId(tilesetId, _block_type)

	if item.AUTOTILE != "FOUR": return
	
	var CurrentTile: int = self.get_cell_source_id(0, _position)
	var LeftTile: int = self.get_cell_source_id(0, _position - Vector2i(1, 0))
	var RightTile: int = self.get_cell_source_id(0, _position + Vector2i(1, 0))
	
	var is_left: bool = LeftTile == tilesetId and CurrentTile == tilesetId
	var is_right: bool = RightTile == tilesetId and CurrentTile == tilesetId
	
	if is_left and not is_right:
		set_cell(0, _position, CurrentTile, Vector2i(1, 0))
	elif is_right and not is_left:
		set_cell(0, _position, CurrentTile, Vector2i(0, 0))
	elif not is_right and not is_left:
		set_cell(0, _position, CurrentTile, Vector2i(1, 1))
	elif is_right and is_left:
		set_cell(0, _position, CurrentTile, Vector2i(0, 1))
	
	if _autotile_surroundings:
		Autotile4(LeftTile, _position - Vector2i(1, 0), false, _block_type)
		Autotile4(RightTile, _position + Vector2i(1, 0), false, _block_type)


func Autotile16(tilesetId: int, _position: Vector2i, _autotile_surroundings: bool, _block_type: String) -> void:
	var item = Data.ItemFromTilesetId(tilesetId, _block_type)
	if item.AUTOTILE != "SIXTEEN": return
	
	# Generate key
	var key: int = 0
	
	var CurrentTile: int = self.get_cell_source_id(0, _position)
	
	var UpperTile: int = self.get_cell_source_id(0, _position - Vector2i(0, 1))
	var LowerTile: int = self.get_cell_source_id(0, _position + Vector2i(0, 1))
	var LeftTile: int = self.get_cell_source_id(0, _position - Vector2i(1, 0))
	var RightTile: int = self.get_cell_source_id(0, _position + Vector2i(1, 0))
	
	var TopLeftTile: int = self.get_cell_source_id(0, _position + Vector2i(-1, -1))
	var TopRightTile: int = self.get_cell_source_id(0, _position + Vector2i(-1, 1))
	var BottomLeftTile: int = self.get_cell_source_id(0, _position + Vector2i(-1, 1))
	var BottomRightTile: int = self.get_cell_source_id(0, _position + Vector2i(1, 1))
	
	if UpperTile != tilesetId: key += 8
	if LowerTile != tilesetId: key += 2
	if LeftTile != tilesetId: key += 1
	if RightTile != tilesetId: key += 4
	
	set_cell(0, _position, CurrentTile, SIXTEEN_TILES[key])
	
	# Special cases
	
	if TopLeftTile != tilesetId: key += 16
	if TopRightTile != tilesetId: key += 128
	if BottomLeftTile != tilesetId: key += 32
	if BottomRightTile != tilesetId: key += 64
	
	if SIXTEEN_TILES_SPECIAL.has(str(key)):
		set_cell(0, _position, CurrentTile, SIXTEEN_TILES_SPECIAL[str(key)])
	
	# Do the 8 surrounding tiles
	if _autotile_surroundings:
		Autotile16(UpperTile, _position - Vector2i(0, 1), false, _block_type)
		Autotile16(LowerTile, _position + Vector2i(0, 1), false, _block_type)
		Autotile16(LeftTile, _position - Vector2i(1, 0), false, _block_type)
		Autotile16(RightTile, _position + Vector2i(1, 0), false, _block_type)
		Autotile16(TopLeftTile, _position + Vector2i(-1, -1), false, _block_type)
		Autotile16(TopRightTile, _position + Vector2i(-1, 1), false, _block_type)
		Autotile16(BottomLeftTile, _position + Vector2i(-1, 1), false, _block_type)
		Autotile16(BottomRightTile, _position + Vector2i(1, 1), false, _block_type)
