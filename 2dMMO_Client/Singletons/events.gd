extends Node

func eventHandler(event, parameters):
	if event == "eventHandler":
		return

	if self.has_method(event):
		self.callv(event, parameters)
	else:
		return

func returnServerMessage(message, icon):
	if message == "Success creating account!":
		Global.AccountMenuNode.LoginAfterRegister()
		return

	if is_instance_valid(Global.NotificationsNode):
		Global.NotificationsNode.Notification(message, icon)

func returnVersionRequest(_valid: bool):
	if _valid:
		get_tree().change_scene_to_file("res://Frames/AccountMenu/AccountMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Frames/OutdatedClientWarning/OutdatedClientWarning.tscn")

func returnLoginRequest(_success: bool, _username: String, database_id: int):
	if _success:
		get_tree().change_scene_to_file("res://Frames/WorldMenu/WorldMenu.tscn")
		Global.Username = _username
		Global.SelfData.DatabaseId = database_id
	else:
		Global.AccountMenuNode.StatusLabel.text = "Login error! Is the username/password correct?"

func returnRegisterRequest(_status: String):
	Global.AccountMenuNode.StatusLabel.text = _status

func returnWorldJoinRequest(_world_data: Dictionary, _inventory: Array, _bits: int, _clothes: Dictionary, permission_level: int):
	
	print("WORLD INFO RECEIVED")
	
	Global.SelfData.Inventory = _inventory
	Global.SelfData.Bits = _bits
	Global.SelfData.Clothes = _clothes
	Global.SelfData.PermissionLevel = permission_level

	var ReceivedWorldData: WorldData = WorldData.new()
	ReceivedWorldData.LoadFromDict(_world_data)
	Global.WorldData = ReceivedWorldData

	if Global.SelfData.DatabaseId == Global.WorldData.OwnerId:
		Global.SelfData.is_owner = true
		Global.SelfData.is_admin = false
	elif Global.SelfData.DatabaseId in Global.WorldData.AdminIds:
		Global.SelfData.is_admin = true
		Global.SelfData.is_owner = false
	else:
		Global.SelfData.is_owner = false
		Global.SelfData.is_admin = false

	Global.LastVisitedPlanet = Global.WorldData.Name
	print(Global.WorldData.OwnerId, "  |  ", Global.WorldData.AdminIds)
	Save.userData.Misc.RecentPlanet = Global.LastVisitedPlanet
	get_tree().change_scene_to_file("res://Frames/World/World.tscn")

func returnWorldLeaveRequest():
	get_tree().change_scene_to_file("res://Frames/WorldMenu/WorldMenu.tscn")

	#if is_instance_valid(Global.WorldNode):
		#Global.WorldNode.queue_free()
	Global.InventoryNode = null

	Global.Peers = {}
	Global.WorldPeers = {}

func returnPlaceBlockRequest(_block_id: int, _position: Vector2i, _peer_id: int):
	if Global.WorldNode:
		Global.WorldNode.WorldBlockManager.PlaceAndAutotile(_block_id, _position, true, _peer_id)

func updateInventory(_slot_data: Array):
	# Bits check
	if int(_slot_data[0]) == -100:
		Global.SelfData.Bits += int(_slot_data[1])
		if Global.WorldNode:
			Global.WorldNode.HUD.display_bits(Global.SelfData.Bits)
		return

	var inventory = Global.SelfData.Inventory
	for slot in inventory:
		if slot[0] == int(_slot_data[0]):
			slot[1] += int(_slot_data[1])
			if Global.InventoryNode:
				Global.InventoryNode.UpdateSlot(_slot_data)
			return

	for slot in inventory:
		if slot[0] == -1:
			slot[0] = int(_slot_data[0])
			slot[1] = int(_slot_data[1])
			if Global.InventoryNode:
				Global.InventoryNode.UpdateSlot(_slot_data)
			return

func breakBlockRequest(_broken_value: int, _position: Vector2i, _peer_id: int):

	if Global.WorldNode:
		Global.WorldNode.WorldBlockManager.BreakBlock(_broken_value, _position, _peer_id)

func returnBlockDrop(_peer_id: int, _drop_data: Array):
	print(_peer_id)
	if _peer_id == multiplayer.get_unique_id():
		print("self")
		Global.WorldNode.Player.CreateDrop(_drop_data)
	else:
		print("other")
		Global.WorldNode.WorldPeerManager.CreateDrop(_peer_id, _drop_data)

func returnUpdatePosition(_peer_id: int, _position: Vector2, _current_state, _direction) -> void:
	if Global.WorldNode:
		Global.WorldNode.WorldPeerManager.UpdatePeer(_peer_id, _position, _current_state, _direction)

func returnEquipClothingRequest(_peer_id: int, _clothing: Dictionary):

	if _peer_id == Global.WorldNode.WorldPeerManager.MultiplayerId:
		Global.SelfData.Clothes = _clothing
		Global.WorldNode.Player.SetClothing(_clothing)
		Global.InventoryNode.SetClothesSlots(_clothing)
	else:
		Global.WorldNode.WorldPeerManager.UpdatePeerClothing(_peer_id, _clothing)

func returnShopPurchaseRequest(_items: Array, _can_buy_again: bool):

	if is_instance_valid(Global.WorldNode):
		Global.WorldNode.ShowRewards(_items, _can_buy_again)

func returnSearchMarketplaceRequest(_search_result: Array):
	if len(Global.WorldNode.WorldGUIManager.gui_stack) > 0 and Global.WorldNode.WorldGUIManager.gui_stack.front() == Global.WorldNode.Marketplace:
		Global.WorldNode.Marketplace.SetListings(_search_result)
	else:
		Global.WorldNode.SellItem.SetListings(_search_result)

func returnBuyListingRequest(listing_id: int):
	if len(Global.WorldNode.WorldGUIManager.gui_stack) > 0 and Global.WorldNode.WorldGUIManager.gui_stack.front() == Global.WorldNode.Marketplace:
		Global.WorldNode.Marketplace.DisableListing(listing_id)
	else:
		Global.WorldNode.SellItem.DisableListing(listing_id)

func returnSetBlockMetadataRequest(position: Vector2i, metadata: Dictionary, player_modified = false):
	print("metadata update: ", metadata, position)
	Global.WorldData.BlockMetadata[str(position)] = metadata
	
	if player_modified:
		var upgrade_SFX = Global.WorldNode.UpdateTileSound.instantiate()
		
		upgrade_SFX.position = position * 32 + Vector2i(16, 16)
		Global.WorldNode.add_child(upgrade_SFX)
	
	if metadata.has("ITEM_ID"):
		Global.WorldNode.WorldBlockManager.UpdateFramedItem(position, metadata.ITEM_ID)
	
	if metadata.has("DIRECTION") and not metadata.has("ITEM_ID"):
		Global.WorldNode.WorldBlockManager.ChangeDirection(position, metadata.DIRECTION)
	if metadata.has("OPEN") and not metadata.has("ITEM_ID"):
		Global.WorldNode.WorldBlockManager.ChangeOpen(position, metadata.OPEN)
		
func returnWorldPermissionUpdate(database_id: int, permission_level: int, player_name: String = ""):
	if permission_level == Global.PERMISSIONS.WORLD_OWNER:
		Global.WorldData.OwnerId = database_id
		if player_name != "":
			Global.WorldData.OwnerName = player_name
	elif permission_level == Global.PERMISSIONS.WORLD_ADMIN:
		Global.WorldData.AdminIds.append(database_id)

	print(database_id)
	print(Global.WorldPeers)

	if Global.SelfData.DatabaseId != database_id:
		for peer_key in Global.WorldPeers:
			var peer = Global.WorldPeers[peer_key]
			if peer.DatabaseId == database_id:
				if permission_level == Global.PERMISSIONS.WORLD_OWNER:
					peer.is_owner = true
				elif permission_level == Global.PERMISSIONS.WORLD_ADMIN:
					peer.is_admin = true
				else:
					peer.is_owner = false
					peer.is_admin = false
	else:
		if permission_level == Global.PERMISSIONS.WORLD_OWNER:
			Global.SelfData.is_owner = true
		elif permission_level == Global.PERMISSIONS.WORLD_ADMIN:
			Global.SelfData.is_admin = true
		else:
			Global.SelfData.is_owner = false
			Global.SelfData.is_admin = false

	Global.WorldNode.WorldPeerManager.UpdateName(database_id)

func returnUpdateDropItem(dropped_data):

	Global.WorldNode.DroppedItemUpdate(dropped_data)

func returnPickupItem(_drop_uid, _peer_id):
	print("picking up item")

	for dropped in Global.WorldNode.Dropped.get_children():
		if dropped.drop_UID == _drop_uid:
			dropped.initiatePickup(_peer_id)

func returnPeerJoined(_peer_id: int, _peer_name: String, _clothes: Dictionary, permission_level: int, database_id: int):
	Global.WorldNode.WorldPeerManager.AddPeer(_peer_id, _peer_name, _clothes, permission_level, database_id)

func returnPeerLeft(_peer_id: int):
	print(_peer_id, " left the world.")
	Global.WorldNode.WorldPeerManager.RemovePeer(_peer_id)

func returnSummonPlayer(world_name, position):
	Server.worldJoinRequest(world_name)
	Server.summon_position = position

func returnSetPlayerPosition(position):
	if is_instance_valid(Global.PlayerNode):
		Global.PlayerNode.position = position

func returnMessageRequest(_nickname: String, _message: String, _peer_id: int, forced_by_server: bool = false):

	Global.ChatNode.incomingMessage(_nickname, _message)


	if _peer_id == Global.WorldNode.WorldPeerManager.MultiplayerId:
		print("YOU SENT THIS MESSAGE NOT THEM")
		Global.PlayerNode.messageSent(_message, forced_by_server)
	else:
		Global.WorldNode.WorldPeerManager.PeerMessage(_peer_id, _message, forced_by_server)
		print("MESSAGE SENT BY THEM")

func returnEmailPrompt():
	if is_instance_valid(Global.EmailPrompt):
		Global.EmailPrompt.close()

func emailPrompt():
	if is_instance_valid(Global.worldMenu):
		Global.worldMenu.promptEmail()

func backgroundUpdate(id):
	Global.WorldData.Background = id
	Global.backgroundNode.SetBackground(id, true)
	Global.WorldNode.Settings.change_sound(id)

func lowGravityUpdate(boolean):
	Global.WorldData.LOW_GRAVITY = boolean
	Global.PlayerNode.gravityCheck()

func worldAdminsListUpdate(adminIds):
	Global.WorldData.AdminIds = adminIds

func killPlayer(spawn_location):
	print("death")
	Global.PlayerNode.Die()
	await get_tree().create_timer(2).timeout
	#Global.PlayerNode.position = spawn_location * 32 + Vector2i(16, 16)
	
	Server.rpc_id(1, "sendEvent", "deathAcknowledgement", [])

func returnPromotedPlanet(planet_name):
	Global.worldMenu.promoted_planet_button.text = planet_name
	Global.worldMenu.promoted_planet_button.disabled = false

func returnBhutanQuestStatus(status):
	Global.WorldNode.BhutanQuest.returnStatus(status)
