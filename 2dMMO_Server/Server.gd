extends Node

const PORT: int = 27015
const MAX_PLAYERS: int = 4095
const max_connections_per_ip: int = 3
const max_connections_per_second: int = 4

#var dtls := DTLSServer.new()
@onready var network := ENetMultiplayerPeer.new()

var SaveThread

@onready var saveTimer: Timer = $SaveTimer
var SaveIntervalSeconds: int = 600

var peers = {}
var addresses = {}

var promoted_planet = ""

func _ready():

	Global.server = self
	print(Global.DATABASE_PATH)
	
	network.create_server(PORT, MAX_PLAYERS)
	
	multiplayer.multiplayer_peer = network
	
	network.connect("peer_connected", _peer_connect)
	network.connect("peer_disconnected", _peer_disconnect)
	
	Folders.CreateFolders()
	SaveThread = Thread.new()
	
	saveTimer.start(SaveIntervalSeconds)
	

func _exit_tree() -> void:
	for peer_id in Peers.ActivePeers:
		Peers.ActivePeers[peer_id].LeaveWorld()
		Peers.ActivePeers[peer_id].SaveInventory()
	
	for world_name in Worlds.ActiveWorlds:
		Worlds.ActiveWorlds[world_name].Save()
	
	Database.Close()

func _on_save_timer_timeout():
	
	print("PRE-SAVE STAMP - " + str(Time.get_unix_time_from_system()))
	
	SaveThread.start(SaveServerInformation, Thread.PRIORITY_NORMAL)
	var result = SaveThread.wait_to_finish()
	saveTimer.start(SaveIntervalSeconds)
	
	print("AFTER-SAVE STAMP - " + str(Time.get_unix_time_from_system()))

func SaveServerInformation():
	
	for player in Peers.ActivePeers:
		Peers.ActivePeers[player].SaveInventory()
	
	for world in Worlds.ActiveWorlds:
		Worlds.ActiveWorlds[world].Save()


@rpc("any_peer")
func sendEvent(event, params):
	var peer_id = multiplayer.get_remote_sender_id()
	$Events.eventHandler(event, params, peer_id)

@rpc
func returnEvent():
	pass

func _peer_connect(_peer_id: int):
	
	var address: String = network.get_peer(_peer_id).get_remote_address()
	
	if address in addresses:
		if addresses[address] >= max_connections_per_ip:
			
			Peers.kickPeer(_peer_id)
			return
	
	if not address in addresses:
		addresses[address] = 1
	else:
		addresses[address] += 1
	
	peers[str(_peer_id)] = {"address": str(address)}
	
func _peer_disconnect(_peer_id: int):
	print("peer disconnected")
	var Peer: PeerData = Peers.GetById(_peer_id)
	Peer.LeaveWorld()
	Peer.SaveInventory()
	
	if Peer.PeerId != -1:
		Peers.RemovePeer(_peer_id)
	
	print(Peers.ActivePeerNames)
	
	if str(_peer_id) in peers and "address" in peers[str(_peer_id)]:
		var address = peers[str(_peer_id)]["address"]
		if address in addresses:
			if addresses[address] <= 1:
				addresses.erase(address)
				print("erased ip")
			else:
				addresses[address] -= 1
				print("removed by 1")
	
	peers.erase(str(_peer_id))

func peerKick(peer_id):
	network.disconnect_peer(peer_id)
	_peer_disconnect(peer_id)

#@rpc("any_peer")
#func Checksum(AntiModifyList: Dictionary):
	#var peer_id: int = multiplayer.get_remote_sender_id()
	#
	#if not AntiModifyList.has("EngineRan") or not AntiModifyList.has("ApplicationCheckSum"):
		#Peers.kickPeer(peer_id)
		#return
	#
	#if AntiModifyList.EngineRan:
		#peers[str(peer_id)] = {"EngineRan": AntiModifyList.EngineRan}
		#print("Player is playing on an editor")
	#else:
		#if AntiModifyList["ApplicationCheckSum"] != GenerateHashedChecksum(peer_id, Global.CHECKSUM_HASH):
			#Peers.kickPeer(peer_id)
			#return
