extends Node

var ActivePeers: Dictionary = {}
var ActivePeerNames: Dictionary = {}

@onready var server = get_parent()

func AddPeer(_peer_id: int, _name: String, database_id: int) -> void:
	var PeerIdKey: String = str(_peer_id)
	var NewPeer: PeerData = PeerData.new()

	NewPeer.PeerId = _peer_id
	NewPeer.Name = _name
	NewPeer.DatabaseId = database_id
	
	
	var QuestFilePath: String = Global.QUESTS_PATH + "/" + str(database_id)

	# If file exists, open it and load contentss
	if FileAccess.file_exists(QuestFilePath):
		var QuestFile: FileAccess = FileAccess.open(QuestFilePath, FileAccess.READ)

		# Load values into self and close
		var SaveDictionary = QuestFile.get_var()
		NewPeer.Quests = SaveDictionary
		print("Loaded player's quests")
	
	ActivePeers[PeerIdKey] = NewPeer
	ActivePeerNames[_name.to_upper()] = NewPeer


func RemovePeer(_peer_id: int) -> void:
	var PeerIdKey: String = str(_peer_id)
	var Name = ActivePeers[PeerIdKey].Name.to_upper()
	ActivePeers.erase(PeerIdKey)
	ActivePeerNames.erase(Name)


func GetById(_peer_id: int) -> PeerData:

	# Set peer id to a string key
	var PeerIdKey: String = str(_peer_id)

	if ActivePeers.has(PeerIdKey):
		return ActivePeers[PeerIdKey]
	else:
		return PeerData.new()

func GetByName(_name: String) -> PeerData:
	
	if ActivePeerNames.has(_name.to_upper()):
		return ActivePeerNames[_name.to_upper()]
	else:
		return PeerData.new()

func SendMessage(peer_id: int, message: String, icon: int) -> void:
	Global.server.rpc_id(peer_id, "returnEvent", "returnServerMessage", [message, icon])
	
# ICON IDS AND WHAT THEY MEAN
# 0 - Reward
# 1 - Announcement
# 2 - Incorrect or warning
# 3 - Locked
# 4 - Achievement
# 5 - Empty, no icon

func SendToPeers(_rpc_func: Callable) -> void:
	for Peer in ActivePeers:
		var PeerId: int = ActivePeers[Peer].PeerId
		_rpc_func.call(PeerId)

func kickPeer(_peer_id: int):
	var peer: PeerData = Peers.GetById(_peer_id)
	Global.server.peerKick(_peer_id)
	print("Server kicked peer_" + str(_peer_id))

func PeerLeaveWorldBroadcast(_peer: PeerData) -> void:
	var World: WorldData = Worlds.GetByName(_peer.CurrentWorldName, _peer)
	World.SendToOtherPeers(_peer.PeerId, func(peer_id):
		Global.server.rpc_id(peer_id, "returnEvent", "returnPeerLeft", [_peer.PeerId])
	)

func authenticateAdminLevel(target_level, _PeerData):
	
	if _PeerData.PermissionLevel >= target_level:
		return true
	
	return false
