class_name WorldData

var server = Global.server


## Vars
# Properties
var WorldSize: Vector2i = Vector2i(75, 50)
var BlockArray: Array
var DroppedData: Dictionary
var BrokenBlocks: Dictionary
var BlockMetadata: Dictionary
var Name: String
var Id: int = 0
var OwnerId: int = -1
var OwnerName: String = ""
var AdminIds = []
var ActivePeers: Array[PeerData]
var Valid: bool
const MAX_WORLD_NAME_LENGTH: int = 32
var LowGravity: bool = false
var Background: int = 0

# Private vars
const _GENERATION_HEIGHT_SCALE: int = 10
const _NOISE_SCALE: int = 5
const _SKY_SIZE: int = 30

const _METADATA_DEFAULTS: Dictionary = {
	_ALL = {DIRECTION = false},
	SIGN = {SIGN_TEXT = ""},
	DOOR = {DOOR_LOCATION = ""},
	LIGHT = {DIRECTION = false},
	ENTRANCE = {OPEN = false},
	DECORATION = {DIRECTION = false},
	CRAFTING = {DIRECTION = false},
	DISPLAY = {ITEM_ID = 0},
	NPC = {DIRECTION = false}
}
const _MAX_ADMIN_COUNT: int = 100
var itemMaxStack: int = 99999999

var door_position = Vector2i.ZERO

var slotMaxStack: int = 10
enum ADMIN_RESULT { SUCCESS, ALREADY_ADMIN, MAX_ADMINS }

## Methods
# Saves world to file
func Save() -> void:

	if self.Name == "":
		return

	# Open file
	var WorldFilePath: String = Global.WORLDS_PATH + "/" + str(self.Id)
	var WorldFile: FileAccess = FileAccess.open(WorldFilePath, FileAccess.WRITE_READ)
	print(WorldFilePath)
	# Create the necessary dict to save the world
	var SaveDictionary: Dictionary = IntoDict(false)
	# Store dictionary to file and close file
	WorldFile.store_var(SaveDictionary)
	WorldFile.close()

# Loads world from file, or creates it if theres no file found
func Load(_name: String, _peer: PeerData) -> void:
	
	
	self.Id = Database.RetrieveWorldId(_name)

	# Get file directory
	var WorldFilePath: String = Global.WORLDS_PATH + "/" + str(self.Id)

	# If file exists, open it and load contentss
	if FileAccess.file_exists(WorldFilePath):
		var WorldFile: FileAccess = FileAccess.open(WorldFilePath, FileAccess.READ)

		# Load values into self and close
		var SaveDictionary = WorldFile.get_var()
		
		self.WorldSize = SaveDictionary.WORLD_SIZE
		self.BlockArray = SaveDictionary.BLOCK_ARRAY

		self.DroppedData = SaveDictionary.DROP_DATA

		self.Name = SaveDictionary.NAME
		self.OwnerId = SaveDictionary.OWNER_ID
		self.OwnerName = SaveDictionary.OWNER_NAME
		self.AdminIds = SaveDictionary.ADMIN_IDS
		self.BrokenBlocks = SaveDictionary.BROKEN_BLOCKS
		self.BlockMetadata = SaveDictionary.BLOCK_METADATA
		self.Background = SaveDictionary.BACKGROUND
		self.LowGravity = SaveDictionary.LOW_GRAVITY
		self.Valid = true
		WorldFile.close()
		
	# If the file doesn't exist, return false
	else:

		var day: int = Date.GetDay()
		if _peer.GeneratedWorldDay == day:
			_peer.TotalGeneratedWorlds += 1
		else:
			_peer.GeneratedWorldDay = day
			_peer.TotalGeneratedWorlds = 1

		if _peer.TotalGeneratedWorlds > 20:
			self.Valid = false
		else:
			self.Valid = true
			self.BlockArray = _GenerateBlockArray()
			self.Name = _name
	
	for z in 2:
		for x in WorldSize.x:
			for y in WorldSize.y:
				var blockId: int = BlockArray[z][x][y]
				
				if blockId == 22:
					door_position = Vector2i(x, y)
					break

# Turns world data into a dictionary
func IntoDict(_include_peers: bool) -> Dictionary:
	var WorldDictionary: Dictionary = {
		WORLD_SIZE = WorldSize,
		BLOCK_ARRAY = BlockArray,
		DROP_DATA = DroppedData,
		NAME = Name,
		OWNER_ID = OwnerId,
		OWNER_NAME = OwnerName,
		ADMIN_IDS = AdminIds,
		BROKEN_BLOCKS = BrokenBlocks,
		BLOCK_METADATA = BlockMetadata,
		BACKGROUND = Background,
		LOW_GRAVITY = LowGravity
	}

	if _include_peers:
		WorldDictionary.PEERS = []
		for peer in ActivePeers:
			var PeerDictionary = {
				PEER_ID = peer.PeerId,
				NAME = peer.Name,
				CLOTHES = peer.Clothes,
				PERMISSION_LEVEL = peer.PermissionLevel,
				DATABASE_ID = peer.DatabaseId,
				POSITION = peer.Position
			}
			WorldDictionary.PEERS.append(PeerDictionary)
	return WorldDictionary


func AddPeer(_peer: PeerData) -> void:
	self.ActivePeers.append(_peer)


func RemovePeer(_peer: PeerData) -> void:
	_peer.PreviousPosition = Vector2.ZERO
	self.ActivePeers.erase(_peer)
	if len(self.ActivePeers) == 0:
		Worlds.CloseWorld(self.Name)


func SendToPeers(_rpc_func: Callable) -> void:
	for Peer in ActivePeers:
		var PeerId: int = Peer.PeerId
		_rpc_func.call(PeerId)


func SendToOtherPeers(_excluded_peer_id: int, _rpc_func: Callable) -> void:
	for Peer in ActivePeers:
		var PeerId: int = Peer.PeerId
		if PeerId != _excluded_peer_id:
			_rpc_func.call(PeerId)


func SetBlock(_block_id: int, _position: Vector2i) -> bool:

	var blockData: Dictionary = Data.ItemData[str(_block_id)]
	var layer: int

	if blockData.TYPE == "BLOCK":
		layer = 0
	elif blockData.TYPE == "BACKGROUND":
		layer = 1
	else:
		return false

	if _position.x >= len(self.BlockArray[layer]) and _position.y >= len(self.BlockArray[layer][0]):
		return false

	if self.BlockArray[layer][_position.x][_position.y] != -1:
		return false

	if _position.x >= 0 and _position.x < self.WorldSize.x and _position.y >= 0 and _position.y < self.WorldSize.y and self.BlockArray[layer][_position.x][_position.y] == -1:
		self.BlockArray[layer][_position.x][_position.y] = _block_id

		if blockData.has("SPECIALTY") and blockData.SPECIALTY in _METADATA_DEFAULTS.keys():
			var default_metadata := SetBlockMetadataDefaults(_position, blockData.SPECIALTY)


		return true
	else:
		return false


func BreakBlock(_position: Vector2i, break_multiplier = 1, peer_id = -1) -> Dictionary:

	if IsInBounds(_position) == false:
		return {Action = "NONE", BrokenValue = 0}
	
	var Peer: PeerData = Peers.GetById(peer_id)
	
	var BlockId: int = self.BlockArray[0][_position.x][_position.y]
	var BackgroundId: int = self.BlockArray[1][_position.x][_position.y]
	var key: String
	var hardness: float
	var layer: int

	# Create key
	if BlockId != -1:
		key = "0," + str(_position.x) + "," + str(_position.y)
		hardness = Data.ItemData[str(BlockId)].HARDNESS
		layer = 0
	elif BackgroundId != -1:
		key = "1," + str(_position.x) + "," + str(_position.y)
		hardness = Data.ItemData[str(BackgroundId)].HARDNESS
		layer = 1
	else:
		return {Action = "NONE", BrokenValue = 0}

	if BrokenBlocks.has(key) and hardness > 0:

		if Time.get_ticks_msec() - BrokenBlocks[key].time >= 15000:
			BrokenBlocks[key].brokenness = floor(hardness - break_multiplier)
		else:
			BrokenBlocks[key].brokenness -= break_multiplier

		BrokenBlocks[key].time = Time.get_ticks_msec()

		if BrokenBlocks[key].brokenness <= 0:
			BrokenBlocks.erase(key)
			BlockArray[layer][_position.x][_position.y] = -1


			if BlockMetadata.has(str(_position)):
				print(BlockMetadata[str(_position)])
				if BlockMetadata[str(_position)].has("ITEM_ID"):
					if BlockMetadata[str(_position)].ITEM_ID != 0:
						Peer.UpdateInventory(BlockMetadata[str(_position)].ITEM_ID, 1) # give item that already is hung up
						Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[BlockMetadata[str(_position)].ITEM_ID, 1]])
						
						SendToPeers(func(_peer_id: int):
							Global.server.rpc_id(_peer_id, "returnEvent", "returnBlockDrop", [peer_id, [BlockMetadata[str(_position)].ITEM_ID, 1]])
						)
						
						BlockMetadata[str(_position)].ITEM_ID = 0
			
			# Delete block metadata if it exists
			var position_str := str(_position)
			if BlockMetadata.has(position_str):
				BlockMetadata.erase(position_str)

			# Get block drops
			var id_to_check: int
			if layer == 0:
				id_to_check = BlockId
			elif layer == 1:
				id_to_check = BackgroundId
			
			if Data.ItemData[str(id_to_check)].has("DROPS"):
				var drops: Array = Random.WeightedRandom(Data.ItemData[str(id_to_check)].DROPS)
				if drops[0] != -1:
					return {Action = "DESTROY", BrokenValue = 0, Drops = drops, BlockID = id_to_check}

			return {Action = "DESTROY", BrokenValue = 0, BlockID = id_to_check}
		else:

			return {Action = "BREAK", BrokenValue = BrokenBlocks[key].brokenness}

	elif hardness > 0:

		BrokenBlocks[key] = {brokenness = floor(hardness - break_multiplier), time = Time.get_ticks_msec()}

		if BrokenBlocks[key].brokenness <= 0:
			BrokenBlocks.erase(key)
			BlockArray[layer][_position.x][_position.y] = -1

			# Get block drops
			var id_to_check: int
			if layer == 0:
				id_to_check = BlockId
			elif layer == 1:
				id_to_check = BackgroundId

			if Data.ItemData[str(id_to_check)].has("DROPS"):
				var drops: Array = Random.WeightedRandom(Data.ItemData[str(id_to_check)].DROPS)
				if drops[0] != -1:
					return {Action = "DESTROY", BrokenValue = 0, Drops = drops, BlockID = id_to_check}

			return {Action = "DESTROY", BrokenValue = 0, BlockID = id_to_check}

		return {Action = "BREAK", BrokenValue = floor(hardness - break_multiplier)}
	else:
		
		if Peers.authenticateAdminLevel(5, Peer):
			BrokenBlocks.erase(key)
			BlockArray[layer][_position.x][_position.y] = -1
			return {Action = "DESTROY", BrokenValue = 0}
		
		return {Action = "NONE", BrokenValue = 0}

func getDroppedItems(position: Vector2):

	var key = str(position.x) + "," + str(position.y)

	if self.DroppedData.has(key):
		return self.DroppedData[key]
	else:
		self.DroppedData[key] = {"dropped": []}

	return self.DroppedData[key]

func getCoordsFromUID(dropped_UID: String) -> Vector2i:
	var coords_str = dropped_UID.split("_")[0]  # Get the substring before the first "_"
	var coords = coords_str.split("x")  # Split by "x" to get X and Y parts
	var x = int(coords[0])
	var y = int(coords[1])
	return Vector2i(x, y)

func CreateDropData(item_id: int, amount: int, position: Vector2, _peer_id: int):
	var Peer: PeerData = Peers.GetById(_peer_id)
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)

	randomize()

	var dropped_items = getDroppedItems(position)

	var dropped_UID = str(position.x) + "x" +str(position.y) + "_" +str(randi()) + str(len(dropped_items)).sha256_text().substr(0, 24)

	var create_data = [item_id, amount, dropped_UID]

	dropped_items["dropped"].append([item_id, amount, dropped_UID])


	World.SendToPeers(func(_peer_id: int): # this will basically create a dropped item in the game
		Global.server.rpc_id(_peer_id, "returnEvent", "returnUpdateDropItem", [create_data])
	)

	print("DROPPED ITEM!")

func DropItem(_item_id, _amount, _position, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)

	if IsCollidable(GetBlock(_position, 0)):
		Peers.SendMessage(peer_id, "You can't drop right there!", 2)
		return
	
	var dropped_items = getDroppedItems(_position)
	
	if len(dropped_items.dropped) == itemMaxStack:
		Peers.SendMessage(peer_id, "Too many dropped items here!", 2)
		return
	
	Peer.UpdateInventory(_item_id, -_amount)
	Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[_item_id, -_amount]])
	
	if Peer.Clothes == Peer.GetValidClothes():
		pass
	else:
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(_peer_id, "returnEvent", "returnEquipClothingRequest", [peer_id, Peer.GetValidClothes()])
		)

	for item in dropped_items["dropped"]:
		if item[0] == _item_id:

			if item[1] + _amount <= itemMaxStack:
				item[1] += _amount

				World.SendToPeers(func(_peer_id: int): # this will basically update an already existing dropped item in the game
					Global.server.rpc_id(peer_id, "returnEvent", "returnUpdateDropItem", [item])
				)

				return

			else:
				# add amount just to fill up the itemMaxStack, and remove that amount added from the original
				var amount_left_to_fill_stack = itemMaxStack - item[1]

				_amount -= amount_left_to_fill_stack
				item[1] += amount_left_to_fill_stack

	# tried all possible stacks, and cant find one.
	if len(dropped_items["dropped"]) < slotMaxStack:

		CreateDropData(_item_id, _amount, _position, peer_id)

	else: # send back excess items that couldnt be dropped
		Peer.UpdateInventory(_item_id, _amount) # put back refused dropped items to inventory
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[_item_id, _amount]])


func itemDropPickup(_dropped_UID, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)

	var picked_up = false

	#if GetBlock(_player_block_position, 0) != -1:
		#print("Block exists on top of dropped item, cant pick it up")
		#return

	#var dropped_items = getDroppedItems(_player_block_position)

	for slot in DroppedData:
		for item in DroppedData[slot]["dropped"]:
			if item[2] == _dropped_UID:

				if IsCollidable(GetBlock(getCoordsFromUID(item[2]), 0)): return

				var dropped_position = Global.getVector2CoordsFromUID(_dropped_UID)

				#if floor(AntiCheat.convertToRegularPosition(dropped_position).distance_to(Peer.Position)) > 40:
					#print(AntiCheat.convertToRegularPosition(dropped_position))
					#print("DISTANCE: ", str(AntiCheat.convertToRegularPosition(dropped_position).distance_to(Peer.Position)))
					#print("not in position to pickup")
					#return

				var item_id = item[0]
				var amount = item[1]

				if Peer.InventoryHasAmount(item_id, 1):

					var amt_left_to_max_slot = itemMaxStack - Peer.InventoryItemAmount(item_id)

					if amount <= amt_left_to_max_slot:

						picked_up = true

						DroppedData[slot]["dropped"].erase(item)
						Peer.UpdateInventory(item_id, amount)
						Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[item_id, amount]])

						World.SendToPeers(func(_peer_id: int):
							Global.server.rpc_id(_peer_id, "returnEvent", "returnBlockDrop", [peer_id, [item_id, amount]])
						)
						break

					else:

						var updated_amount = amount - amt_left_to_max_slot

						if amt_left_to_max_slot <= 0:
							Peers.SendMessage(peer_id, "You're already holding more than enough!", 2)
							return

						if updated_amount > 0:

							Peer.UpdateInventory(item_id, amt_left_to_max_slot)
							Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[item_id, amt_left_to_max_slot]])

							item[1] = updated_amount

							World.SendToPeers(func(_peer_id: int):
								Global.server.rpc_id(_peer_id, "returnEvent", "returnUpdateDropItem", [item])
							)

							World.SendToPeers(func(_peer_id: int):
								Global.server.rpc_id(_peer_id, "returnEvent", "returnBlockDrop", [peer_id, [item_id, amt_left_to_max_slot]])
							)
				else:

					if Peer.GetFreeInventorySlots() == 0:

						Peers.SendMessage(peer_id, "Cannot pick up, full inventory!", 2)

					else:

						var amount_to_give = 0
						var update_amount = 0

						if amount >= itemMaxStack: # if stack is greater than 999
							amount_to_give = itemMaxStack
							update_amount = amount - itemMaxStack
						else:
							amount_to_give = amount

						if update_amount > 0:
							item[1] = update_amount

							Peer.UpdateInventory(item_id, amount_to_give)
							Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[item_id, amount_to_give]])

							World.SendToPeers(func(_peer_id: int):
								Global.server.rpc_id(_peer_id, "returnEvent", "returnUpdateDropItem", [item])
							)

						else:
							picked_up = true

							DroppedData[slot]["dropped"].erase(item)

							Peer.UpdateInventory(item_id, amount)
							Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[item_id, amount]])

							World.SendToPeers(func(_peer_id: int):
								Global.server.rpc_id(_peer_id, "returnEvent", "returnBlockDrop", [peer_id, [item_id, amount]])
							)

	if picked_up:
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(_peer_id, "returnEvent", "returnPickupItem", [_dropped_UID, peer_id])
		)
		pass

# Generates world
func _GenerateBlockArray() -> Array:
	var GenerationArray: Array = [[],[]] # index 0 is blocks, index 1 is backgrounds

	var dirt_heights: Array = []

	var NoiseTexture: FastNoiseLite = FastNoiseLite.new()
	NoiseTexture.seed = randi_range(-2147483647, 2147483647)

	# Block layer
	for x in WorldSize.x:
		var NewPackedBlockArray: PackedInt32Array = []
		var NewPackedBackgroundArray: PackedInt32Array = []
		var XHeight: float = NoiseTexture.get_noise_1d(x / Global.WorldGenProperties.Scale) * Global.WorldGenProperties.Amplitude
		dirt_heights.append(ceil(_SKY_SIZE + XHeight - Global.WorldGenProperties.HeightBuffer))
		GenerationArray[0].insert(x, NewPackedBlockArray)
		GenerationArray[1].insert(x, NewPackedBackgroundArray)
		for y in WorldSize.y:

			# Dirt mounds and sky; fills out the entire array
			if y > _SKY_SIZE + XHeight - Global.WorldGenProperties.HeightBuffer:
				GenerationArray[0][x].append(1)
				GenerationArray[1][x].append(31)

			else:
				GenerationArray[0][x].append(-1)
				GenerationArray[1][x].append(-1)

			# Lava
			if y >= WorldSize.y - 6 and randi_range(1, 4) == 1 and GenerationArray[0][x][y] != -1:
				GenerationArray[0][x][y] = 4

			# Rocks and ore
			if randi_range(1, 20) == 1 and GenerationArray[0][x][y] != -1 and y > 4 and GenerationArray[0][x][y - 4] != -1:
				GenerationArray[0][x][y] = 2
				randomize()
				var chance = randi() % 1000
				print(chance)
				if chance < 500:
					GenerationArray[0][x][y] = 174 # cobalt
				if chance < 300: # 30%
					GenerationArray[0][x][y] = 181 # promethium
				if chance < 50: # 5%
					GenerationArray[0][x][y] = 185 # diamond
				if chance < 1: # 0.1%
					GenerationArray[0][x][y] = 183 # dragonite
				
			if randi_range(1, 20) == 1 and GenerationArray[0][x][y] != -1 and y > 4 and GenerationArray[0][x][y - 4] != -1:
				GenerationArray[0][x][y] = 12

			# Bedrock
			if y >= WorldSize.y - 2:
				GenerationArray[0][x][y] = 3


	# Grass and bushes
	for x in dirt_heights.size():
		var grass_chosen: int = randi_range(0, 2)
		if grass_chosen == 2:
			var id
			var randi = randi_range(0, 1)
			
			if randi == 0:
				id = 60
			else:
				id = 67
			if x != 0: # don't know why i need this but i do
				GenerationArray[0][x][dirt_heights[x] - 1] = id # ID 24 is grass pile ID, ID 60 for autumn leaves
			else:
				GenerationArray[0][x][dirt_heights[x]] = id

		#var bush_chosen: int = randi_range(0, 17)
		#if bush_chosen == 0:
			#var bush_type: int = randi_range(0, 2)
			#if bush_type == 0:
				#GenerationArray[0][x][dirt_heights[x] - 1] = 25
			#elif bush_type == 1:
				#GenerationArray[0][x][dirt_heights[x] - 1] = 26
			#elif bush_type == 2:
				#GenerationArray[0][x][dirt_heights[x] - 1] = 30

		var rocks_chosen: int = randi_range(0, 15)
		if rocks_chosen == 0:
			GenerationArray[0][x][dirt_heights[x] - 1] = 78
			
	# Entrance
	var entrance_x: int = randi_range(0, self.WorldSize.x - 1)
	GenerationArray[0][entrance_x][dirt_heights[entrance_x] - 1] = 22
	GenerationArray[0][entrance_x][dirt_heights[entrance_x]] = 3

	return GenerationArray


func GetBlock(position: Vector2i, layer: int) -> int:
	return self.BlockArray[layer][position.x][position.y]

func IsBlock(position: Vector2i, layer: int) -> bool:
	var id = self.BlockArray[layer][position.x][position.y]

	if id == -1: # no block or prop
		return false

	var block_item_data = Data.ItemData[str(id)]

	if block_item_data["CAN_COLLIDE"]:
		return true


	return false



func IsCollidable(id: int) -> bool:

	if id == -1: # no block or prop
		return false

	if id == 22: # planet entrance // dont allow
		return true

	var block_item_data = Data.ItemData[str(id)]

	if block_item_data["CAN_COLLIDE"]:
		return true
	else:
		return false

func IsInBounds(_position: Vector2i) -> bool:
	return not (_position.x >= len(self.BlockArray[0]) and _position.y >= len(self.BlockArray[0][0]))



func SetBlockMetadataDefaults(position: Vector2i, specialty: String) -> Dictionary:
	var default_metadata := _METADATA_DEFAULTS._ALL.duplicate()
	default_metadata.merge(_METADATA_DEFAULTS[specialty].duplicate())

	BlockMetadata[str(position)] = default_metadata
	return default_metadata


func SetBlockMetadata(position: Vector2i, metadata: Dictionary, specialty: String, peer) -> Dictionary:
	
	print("!!!!",metadata)
	
	var position_str := str(position)
	if not BlockMetadata.has(position_str):
		BlockMetadata[position_str] = {}
	
	metadata = _sanitize_metadata(metadata, specialty)
	if len(metadata) == 0: return {}
	
	print(specialty)
	
	if specialty == "DISPLAY":
		if metadata.ITEM_ID == -1: # player attempting to remove item
			peer.UpdateInventory(BlockMetadata[position_str].ITEM_ID, 1) # give item that already is hung up
			Global.server.rpc_id(peer.PeerId, "returnEvent", "updateInventory", [[BlockMetadata[position_str].ITEM_ID, 1]])
			
			SendToPeers(func(_peer_id: int):
				Global.server.rpc_id(_peer_id, "returnEvent", "returnBlockDrop", [peer.PeerId, [BlockMetadata[position_str].ITEM_ID, 1]])
			)
			
			metadata.ITEM_ID = 0
		else:
			
			var item_data = Data.ItemData[str(metadata.ITEM_ID)]
			
			if item_data.has("UNSELLABLE") and item_data.UNSELLABLE == true: return {}
			
			if BlockMetadata[position_str].ITEM_ID != metadata.ITEM_ID: # if not the same item id
					if BlockMetadata[position_str].ITEM_ID == 0: # if no item at all
						if not peer.InventoryHas(metadata.ITEM_ID): # if doesnt have item, dont accept
							return {}
						
						peer.UpdateInventory(metadata.ITEM_ID, -1)
						Global.server.rpc_id(peer.PeerId, "returnEvent", "updateInventory", [[metadata.ITEM_ID, -1]])
					else:
						if not peer.InventoryHas(metadata.ITEM_ID): # if doesnt have item, dont accept
							return {}
						
						peer.UpdateInventory(BlockMetadata[position_str].ITEM_ID, 1) # give item that already is hung up
						Global.server.rpc_id(peer.PeerId, "returnEvent", "updateInventory", [[BlockMetadata[position_str].ITEM_ID, 1]])
						
						SendToPeers(func(_peer_id: int):
							Global.server.rpc_id(_peer_id, "returnEvent", "returnBlockDrop", [peer.PeerId, [BlockMetadata[position_str].ITEM_ID, 1]])
						)
						
						peer.UpdateInventory(metadata.ITEM_ID, -1)
						Global.server.rpc_id(peer.PeerId, "returnEvent", "updateInventory", [[metadata.ITEM_ID, -1]])
	
	for metadata_key in metadata:
		
		BlockMetadata[position_str][metadata_key] = metadata[metadata_key]
	
	print(BlockMetadata[position_str])
	return BlockMetadata[position_str]


func PeerCanEdit(peer_data: PeerData) -> bool:
	return self.OwnerId == -1 or (self.OwnerId == peer_data.DatabaseId or peer_data.DatabaseId in self.AdminIds) or peer_data.PermissionLevel == 5



func PeerOwns(peer_data: PeerData) -> bool:
	return OwnerId == peer_data.DatabaseId


func AddAdmin(database_id: int) -> ADMIN_RESULT:

	if len(AdminIds) == _MAX_ADMIN_COUNT:
		return ADMIN_RESULT.MAX_ADMINS

	if database_id in AdminIds:
		return ADMIN_RESULT.ALREADY_ADMIN

	AdminIds.append(database_id)
	return ADMIN_RESULT.SUCCESS


func RemoveAdmin(database_id: int) -> void:

	if database_id in AdminIds:
		AdminIds.erase(database_id)



func _sanitize_metadata(metadata: Dictionary, specialty: String) -> Dictionary:
	var type_keys: Array = _METADATA_DEFAULTS[specialty].keys()

	for metadata_key in metadata:
		if not metadata_key in type_keys:
			metadata.erase(metadata_key)

	if not metadata.has("DIRECTION"):
		metadata.DIRECTION = false

	return metadata

func isWorldClaimed() -> bool:
	if self.OwnerId == -1:
		return false
	return true
