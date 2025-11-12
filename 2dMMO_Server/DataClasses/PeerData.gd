class_name PeerData

var PeerId: int = -1
var DatabaseId: int = -1
var Name: String = ""
var CurrentWorldName: String = ""

var Muted: int = 0

var deathTimeStamp = 0.0
var death: bool = false
var death_position

var Position: Vector2
var Direction: bool = false # false means facing right, true meaning facing left

var normal_velocity = Vector2i(180, 410)

var BYPASS_ANTICHEAT = false
#### CHEAT PREVENTION STUFF

var MoveStamp
var PreviousMoveStamp

var client_velocity

var PreviousPosition = Vector2.ZERO
	
####
var Inventory: Array = [
	[0, 1], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
	[-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0], [-1, 0],
] # item id, amount; (default size 160)
var Clothes: Dictionary = {
	SHIRT = -1,
	PANTS = -1,
	SHOES = -1,
	TOOL = -1,
	HAT = -1,
	HAIR = -1,
	BACK = -1,
	HAND = -1,
	FACE = -1
}
var Bits: int
var Email: String
var LastBroken: float = Time.get_ticks_msec()
var LastJoined: float = 0
var GeneratedWorldDay: int
var TotalGeneratedWorlds: int
var PermissionLevel: int
var _break_packets_sent: Array = []

const MAX_BREAK_PACKET_BUFFER: int = 10

var Quests = {
	
	"BhutansQuest": {
		"completed": false,
		"collected": false,
		
		"current_step": 1,
		"max_steps": 4,
		
		"quest_reward": [190, 1],
		
		"steps": {
			"1": {
				"ACTION": "PLACE",
				"ID": 192,
				"AMOUNT": 500,
				"CURRENT_AMOUNT": 0,
				"objective": "%s/500 Snow blocks placed.",
				"description": "Spread the word of winter",
			},
			"2": {
				"ACTION": "CRAFT",
				"ID": 194,
				"AMOUNT": 5,
				"CURRENT_AMOUNT": 0,
				"objective": "%s/5 Snowmen crafted.",
				"description": "Create some snowmen",
			},
			"3": {
				"ACTION": "BREAK",
				"TYPE": "BACKGROUND",
				"AMOUNT": 5000,
				"CURRENT_AMOUNT": 0,
				"objective": "%s/5000 Background broken.",
				"description": "Bhutan likes the cold",
			},
			"4": {
				"ACTION": "CLAIM",
				"AMOUNT": 10,
				"CURRENT_AMOUNT": 0,
				"objective": "%s/10 Planets claimed.",
				"description": "Conquer the planets in Pixel Planet",
			},
		},
	}
}


func JoinWorld(_name: String) -> void:
	var World: WorldData = Worlds.GetByName(_name, self)
	CurrentWorldName = _name
	World.AddPeer(self)


func LeaveWorld() -> void:
	if CurrentWorldName != "":
		var World: WorldData = Worlds.GetByName(CurrentWorldName, self)
		Peers.PeerLeaveWorldBroadcast(self)
		World.RemovePeer(self)
		CurrentWorldName = ""

func SaveQuest():
	var QuestFilePath: String = Global.QUESTS_PATH + "/" + str(self.DatabaseId)
	var QuestFile: FileAccess = FileAccess.open(QuestFilePath, FileAccess.WRITE_READ)
	# Store dictionary to file and close file
	QuestFile.store_var(Quests)
	QuestFile.close()

func SaveInventory() -> void:
	Database.SaveInventory(self.Name, self.Inventory, self.Bits, self.Clothes, self.PermissionLevel)
	
	
	# Save Quest
	SaveQuest()

func UpdateInventory(_item_id: int, _amount: int) -> void:
	
	# If the item is bits, then do the bits stuff
	if _item_id == -100:
		self.Bits += _amount
		return
	
	# Find item by index in inventory
	var index: int
	
	for i in len(self.Inventory):
		var slot: Array = self.Inventory[i]
		
		if slot[0] == _item_id or slot[0] == -1:
			slot[0] = _item_id
			index = i
			break
	
	# Update slot
	var slot: Array = self.Inventory[index]
	slot[1] += _amount
	
	# Check if no items left in slot
	if slot[1] <= 0:
		slot[0] = -1
		slot[1] = 0
		
		self.Inventory.pop_at(index)
		self.Inventory.append([-1, 0])



func InventoryHas(_item_id: int) -> bool:
	for slot in self.Inventory:
		if slot[0] == _item_id:
			return true
	return false

func InventoryItemAmount(_item_id: int) -> int:
	for slot in self.Inventory:
		if slot[0] == _item_id:
			return slot[1]
	return 0

func InventoryHasAmount(_item_id: int, _amount: int) -> bool:
	for slot in self.Inventory:
		if slot[0] == _item_id:
			if slot[1] >= _amount:
				return true
			else:
				return false
	return false


func GetFreeInventorySlots() -> int:
	var total_free_slots: int = 0
	
	for slot in self.Inventory:
		if slot[0] == -1:
			total_free_slots += 1
			
	return total_free_slots



func CanBreak() -> bool:
	var time_msec := Time.get_ticks_msec()
	
	var break_packets_length := len(_break_packets_sent)
	
	print("BEFORE: ", _break_packets_sent, " | ", time_msec)
	
	if break_packets_length > 0:
		for i in range(break_packets_length - 1, -1, -1):
			if time_msec >= _break_packets_sent[i]:
				_break_packets_sent.remove_at(i)
				
	print("AFTER: ", _break_packets_sent, " | ", time_msec)
	
	break_packets_length = len(_break_packets_sent)
	if break_packets_length < MAX_BREAK_PACKET_BUFFER:
		if break_packets_length == 0:
			_break_packets_sent.append(time_msec + Global.BREAK_INTERVAL * 1000)
			print(time_msec + Global.BREAK_INTERVAL * 1000, _break_packets_sent)
		else:
			_break_packets_sent.append(_break_packets_sent[break_packets_length - 1] + Global.BREAK_INTERVAL * 1000)
		return true
	else:
		return false


func CanJoin() -> bool:
	if Time.get_ticks_msec() - self.LastJoined >= Global.WORLD_JOIN_INTERVAL * 1000:
		self.LastJoined = Time.get_ticks_msec()
		return true
	else:
		return false


func Equip(_item_id: int) -> Dictionary:
	if not Data.ItemData.has(str(_item_id)): return self.Clothes
	
	var clothing: Dictionary = Data.ItemData[str(_item_id)]
	
	if clothing.TYPE != "CLOTHING": return self.Clothes
	
	var place = clothing.PLACE
	
	if self.Clothes[place] == _item_id:
		self.Clothes[place] = -1
	else:
		self.Clothes[place] = _item_id
	return self.Clothes


func PurchaseShopPack(_shop_id: String) -> Dictionary:

	if not Data.ShopData.has(_shop_id): return {success = false}
	
	var pack_data: Dictionary = Data.ShopData[_shop_id]
	
	if self.Bits < pack_data.PRICE: return {success = false}
	if self.GetFreeInventorySlots() < pack_data.ITEM_AMOUNT: return {success = false}
	
	self.Bits -= pack_data.PRICE
	
	var shop_drops: Array = []
	
	var set_pool: bool = false
	if pack_data.has("SET_POOL"):
		set_pool = true
	
	if set_pool == false:
		for i in pack_data.ITEM_AMOUNT:
			var random_result: Array = Random.WeightedRandom(pack_data.LOOT_POOL)
			
			shop_drops.append(random_result)
			self.UpdateInventory(random_result[0], random_result[1])
	else:
		for loot in pack_data.LOOT_POOL:
			shop_drops.append([loot.ITEM_ID, loot.AMOUNT])
			self.UpdateInventory(loot.ITEM_ID, loot.AMOUNT)
	
	return {success = true, drops = shop_drops, price = pack_data.PRICE}

func GetValidClothes() -> Dictionary:
	
	var valid_clothes: Dictionary = {
		SHIRT = -1,
		PANTS = -1,
		SHOES = -1,
		TOOL = -1,
		HAT = -1,
		HAIR = -1,
		BACK = -1,
		HAND = -1
	}
	
	for index in self.Clothes:
		if self.InventoryHas(self.Clothes[index]):
			valid_clothes[index] = self.Clothes[index]
	
	self.Clothes = valid_clothes
	
	return valid_clothes

func Die():
	var World: WorldData = Worlds.GetByName(CurrentWorldName, self)
	
	deathTimeStamp = Time.get_unix_time_from_system()
	
	self.death = true
	
	PreviousPosition = Vector2(World.door_position)
	death_position = Position
	
	Global.server.rpc_id(PeerId, "returnEvent", "killPlayer", [World.door_position])
