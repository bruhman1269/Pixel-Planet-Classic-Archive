class_name WorldData

## Vars
# Properties
var WorldSize: Vector2i = Vector2i(50, 75)
var BlockArray: Array
var DroppedData: Dictionary
var BrokenBlocks: Dictionary
var Name: String
var OwnerId: int = 0
var OwnerName: String
var AdminIds = []
var ActivePeers: Array
var BlockMetadata: Dictionary

var Background = 0
var LOW_GRAVITY = false

func LoadFromDict(_world_data_dict: Dictionary) -> void:
	self.WorldSize = _world_data_dict.WORLD_SIZE
	self.BlockArray = _world_data_dict.BLOCK_ARRAY
	self.DroppedData = _world_data_dict.DROP_DATA
	self.Name = _world_data_dict.NAME
	self.OwnerId = _world_data_dict.OWNER_ID
	self.OwnerName = _world_data_dict.OWNER_NAME
	self.AdminIds = _world_data_dict.ADMIN_IDS
	self.BrokenBlocks = _world_data_dict.BROKEN_BLOCKS
	self.BlockMetadata = _world_data_dict.BLOCK_METADATA
	self.Background = _world_data_dict.BACKGROUND
	self.LOW_GRAVITY = _world_data_dict.LOW_GRAVITY
	
	for peer in _world_data_dict.PEERS:
		var NewPeerData = PeerData.new()
		NewPeerData.Name = peer.NAME
		print("Peer information test")
		print(Server.Peer.get_peer(peer.PEER_ID))
		
		NewPeerData.PeerId = peer.PEER_ID
		NewPeerData.Clothes = peer.CLOTHES
		NewPeerData.PermissionLevel = peer.PERMISSION_LEVEL
		NewPeerData.DatabaseId = peer.DATABASE_ID
		NewPeerData.Position = peer.POSITION
		
		print("peer dbid: ", NewPeerData.DatabaseId)
		if NewPeerData.DatabaseId == self.OwnerId:
			NewPeerData.is_owner = true
		elif NewPeerData.DatabaseId in self.AdminIds:
			NewPeerData.is_admin = true
		
		ActivePeers.append(NewPeerData)
	
