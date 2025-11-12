extends Node

var MultiplayerId: int

func Init(_multiplayer_id: int) -> void:
	MultiplayerId = _multiplayer_id


func AddPeer(_peer_id: int, _peer_name: String, _clothes: Dictionary, permission_level: int, database_id: int) -> void:
	var newPlayer = preload("res://Scenes/WorldScenes/Player.tscn").instantiate()
	newPlayer.PeerId = _peer_id
	newPlayer.SetClothing(_clothes, true)
	newPlayer.get_node("CollisionShape2D").queue_free()
	newPlayer.get_node("HurtCollider").queue_free()
	Global.WorldNode.Peers.add_child(newPlayer)
	
	var newPeerData: PeerData = PeerData.new()
	newPeerData.PeerId = _peer_id
	newPeerData.Name = _peer_name
	newPeerData.PlayerScene = newPlayer
	newPeerData.Clothes = _clothes
	newPeerData.DatabaseId = database_id
	newPeerData.PermissionLevel = permission_level
	
	if newPeerData.DatabaseId == Global.WorldData.OwnerId:
		newPeerData.is_owner = true
	elif newPeerData.DatabaseId in Global.WorldData.AdminIds:
		newPeerData.is_admin = true
	
	newPlayer.SetName(_peer_name, permission_level, newPeerData)
	
	Global.WorldPeers[_peer_id] = newPeerData


func UpdateName(database_id: int) -> void:
	print("NAMRE UPDATE CALLED")
	if database_id != Global.SelfData.DatabaseId:
		var peer
		for peer_key in Global.WorldPeers:
			var peer_data = Global.WorldPeers[peer_key]
			if peer_data.DatabaseId == database_id:
				peer = peer_data
		
		if peer != null:
			var PeerPlayer = peer.PlayerScene
			PeerPlayer.SetName(PeerPlayer.Username, peer.PermissionLevel, peer)
	else:
		Global.PlayerNode.SetName(Global.Username, Global.SelfData.PermissionLevel, Global.SelfData)


func RemovePeer(_peer_id: int) -> void:
	var currentPeer: PeerData = Global.WorldPeers[_peer_id]
	currentPeer.PlayerScene.queue_free()
	Global.WorldPeers.erase(_peer_id)


func LoadPeers() -> void:
	if not Global.WorldData or len(Global.WorldData.ActivePeers) == 0:
		return
	
	for peer in Global.WorldData.ActivePeers:
		if peer.PeerId != MultiplayerId:
			var newPlayer = preload("res://Scenes/WorldScenes/Player.tscn").instantiate()
			newPlayer.PeerId = peer.PeerId
			newPlayer.SetName(peer.Name, peer.PermissionLevel, peer)
			newPlayer.SetClothing(peer.Clothes, true)
			newPlayer.get_node("CollisionShape2D").queue_free()
			Global.WorldNode.Peers.add_child(newPlayer)
			peer.PlayerScene = newPlayer
			Global.WorldPeers[peer.PeerId] = peer
			newPlayer.position = peer.Position


func UpdatePeer(_peer_id: int, _position: Vector2, _current_state, _direction) -> void:
	var PeerPlayer = Global.WorldPeers[_peer_id].PlayerScene
	PeerPlayer.UpdateAsPeer(_position, _current_state, _direction, _peer_id)


func UpdatePeerClothing(_peer_id: int, _clothes: Dictionary) -> void:
	var PeerPlayer = Global.WorldPeers[_peer_id].PlayerScene
	Global.WorldPeers[_peer_id].Clothes = _clothes
	PeerPlayer.SetClothing(_clothes)


func CreateDrop(_peer_id: int, _drop_data: Array) -> void:
	var PeerPlayer = Global.WorldPeers[_peer_id].PlayerScene
	PeerPlayer.CreateDrop(_drop_data)

func PeerMessage(_peer_id: int, _message: String, forced_by_server) -> void:
	var PeerPlayer = Global.WorldPeers[_peer_id].PlayerScene
	PeerPlayer.messageSent(_message, forced_by_server)

func getPeerNode(_peer_id: int):
	var PeerPlayer = Global.WorldPeers[_peer_id].PlayerScene
	return PeerPlayer
