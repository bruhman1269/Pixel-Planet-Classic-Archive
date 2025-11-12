extends Node

const VERSION: String = "a2.1_blue"
const CHECKSUM_HASH: String = "647f7a42eeb82229c669f27eecc13e0b417204b2c3f66f8c55278b30ada79335" # UPDATE THIS EVERY VERSION OF THE GAME

const DATABASE_PATH: String = "/root/.local/share/godot/app_userdata/pixel_planet_server/db.db" # change to "user://db.db"
const WORLDS_PATH: String = "user://worlds" #user://worlds
const QUESTS_PATH: String = "user://quests" #user://worlds

const WorldGenProperties: Dictionary = {
	Amplitude = 100.0,
	Scale = 15.0,
	HeightBuffer = 8
}
const BREAK_INTERVAL: float = 0.2
const MAX_SIGN_LENGTH: int = 128
const WORLD_JOIN_INTERVAL: float = 4.0
const VALID_CHARACTERS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890 "

var clean_valid_characters = r" `~abcdefghijklmnopqrstuvwxyz0123456789)!@#$%^&*(-=_+\|[]{};:,<.>/?'\""

var server

enum PERMISSIONS { NORMAL = 0, WORLD_OWNER = 1, WORLD_ADMIN = 2, CREATOR = 3, MODERATOR = 4, DEVELOPER = 5 }


func GetArgCount(methodname, methodlist):
	for method in methodlist:
		if method.name == methodname:
			return len(method.args)

func SplitArgs(args, argcount): # sundae, 1
	
	if len(args) < argcount:
		return []
	
	var out_args = []
	for arg in argcount -1:
		out_args.append(args[arg])
	
	for arg in argcount-1:
		args.remove_at(0)
	
	var last_param = ""
	
	for arg in len(args):
		if arg != len(args) - 1:
			last_param += args[arg] + " "
		else:
			last_param += args[arg]
	
	out_args.append(last_param)
	
	return out_args

func getVector2CoordsFromUID(dropped_UID: String) -> Vector2:
	var coords_str = dropped_UID.split("_")[0]  # Get the substring before the first "_"
	var coords = coords_str.split("x")  # Split by "x" to get X and Y parts
	var x = int(coords[0])
	var y = int(coords[1])
	return Vector2(x, y)

func GetValidNameString(name: String) -> bool:
	var name_length: int = len(name)
	
	for char_index in name_length:
		var char: String = name[char_index]
		
		if not char in VALID_CHARACTERS:
			return false
		
		if char == " ":
			if char_index == 0 or char_index == name_length - 1: 
				return false
			if name[char_index - 1] == " " or name[char_index + 1] == " ":
				return false
	
	return true

func cleanText(text):
	
	var new_string = ""

	for chr in text:
		if not chr.to_lower() in clean_valid_characters:
			continue
		else:
			new_string += chr
	
	return new_string


func SendInventoryUpdate(peer_id: int, array: Array) -> void:
	Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [array])


func MetadataCorrectnessCheck(block_item_data: Dictionary, metadata_info: Dictionary) -> bool:
	print(metadata_info)
	print(block_item_data)
	if not metadata_info.has("TYPE"): return false
	if not metadata_info.has("METADATA"): return false
	
	if block_item_data.has("SIGN") and metadata_info.TYPE == "SIGN":
		
		if not metadata_info.METADATA.has("SIGN_TEXT"): return false
		
		if len(metadata_info.METADATA.SIGN_TEXT) <= Global.MAX_SIGN_LENGTH:
			return true
	
	elif block_item_data.has("DOOR") and metadata_info.TYPE == "DOOR":
		
		if not metadata_info.METADATA.has("DOOR_LOCATION"): return false
		
		if len(metadata_info.METADATA.DOOR_LOCATION) <= WorldData.MAX_WORLD_NAME_LENGTH:
			return true
	
	elif block_item_data.has("LIGHT") and metadata_info.TYPE == "LIGHT":
		
		if metadata_info.METADATA.has("DIRECTION"):
			print("correct light metadata")
			return true
		else:
			return false
			
	elif metadata_info.TYPE == "ENTRANCE":
		
		if metadata_info.METADATA.has("OPEN"):
			print("correct entrance metadata")
			return true
		else:
			return false
	
	elif metadata_info.TYPE == "DISPLAY":
		
		if metadata_info.METADATA.has("ITEM_ID"):
			print("correct display metadata")
			return true
		else:
			return false
	
	elif block_item_data.has("SPECIALTY") and block_item_data.SPECIALTY in WorldData._METADATA_DEFAULTS.keys() and metadata_info.TYPE == "_ALL":
		return true
	
	return false

func worldToGrid(world_pos: Vector2) -> Vector2i:
	var grid_x = int(world_pos.x / 32)
	var grid_y = int(world_pos.y / 32)
	return Vector2i(grid_x, grid_y)

func GenerateHashedChecksum(key, checksum):
	var hashed_checksum = checksum
	var rounds = pow(2,9)

	while rounds > 0:
		hashed_checksum = (hashed_checksum + str(key)).sha256_text()
		rounds -= 1
	return hashed_checksum

func isEmailValid(email: String) -> bool:
	var regex = RegEx.new()
	
	var pattern = r"^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$"
	regex.compile(pattern)
	
	var result = regex.search(email.to_lower())
	
	if result:
		print("Email is valid")
		return true
	else:
		print("Email is invalid")
		return false
