extends Node

const CHUNK_SIZE = 1024

var worldMenu
var planetMenu
var backgroundNode
var AccountMenuNode: Control
var WorldNode: Node2D
var PeersNode: Node2D
var EmailPrompt
var InventoryNode: Control
var NotificationsNode: Control
var WorldData: WorldData
var SelfData: PeerData = PeerData.new()
var Peers: Dictionary
var Username: String
var WorldPeers: Dictionary
var LastVisitedPlanet: String = ""
var ChatNode: Control
var CurrentItem: int = -1
var PlayerNode
var DisconnectionNode
var SpecialAnimationsNode
var bhutanQuest

const HIT_INTERVAL: float = 0.2
const VERSION: String = "a2.1_blue"

enum PERMISSIONS { NORMAL = 0, WORLD_OWNER = 1, WORLD_ADMIN = 2, CREATOR = 3, MODERATOR = 4, DEVELOPER = 5 }

var drop_id

func getCoordsFromUID(dropped_UID: String) -> String:
	var coords_str = dropped_UID.split("_")[0]  # Get the substring before the first "_"
	var coords = coords_str.split("x")  # Split by "x" to get X and Y parts
	var x = int(coords[0])
	var y = int(coords[1])
	return (str(x) + "," + str(y))

func getVector2CoordsFromUID(dropped_UID: String) -> Vector2:
	var coords_str = dropped_UID.split("_")[0]  # Get the substring before the first "_"
	var coords = coords_str.split("x")  # Split by "x" to get X and Y parts
	var x = int(coords[0])
	var y = int(coords[1])
	return Vector2(x, y)

func hash_app():
	
	if not FileAccess.file_exists(OS.get_executable_path()):
		return
	
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	
	var file = FileAccess.open(OS.get_executable_path(), FileAccess.READ)
	
	while not file.eof_reached():
		ctx.update(file.get_buffer(CHUNK_SIZE))
	
	var res = ctx.finish()
	
	return Global.GenerateHChecksum(Server.self_peer_id, res.hex_encode())

func GenerateHChecksum(key, checksum):
	var hashed_checksum = checksum
	var rounds = pow(2,9)

	while rounds > 0:
		hashed_checksum = (hashed_checksum + str(key)).sha256_text()
		rounds -= 1
	return hashed_checksum

func comma_sep(number: int) -> String:
	var string = str(number)
	var mod = string.length() % 3
	var res = ""

	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]

	return res
