extends Node

@onready var server = get_parent()

func eventHandler(event, parameters, peer_id):
	if event == "eventHandler":
		return
	
	if typeof(parameters) != TYPE_ARRAY:
		return
	
	if self.has_method(event):
		parameters.append(peer_id)
		self.callv(event, parameters)
	else:
		return

func versionCheck(_version: String, peer_id):
	var version_is_correct = _version == Global.VERSION
	Global.server.rpc_id(peer_id, "returnEvent", "returnVersionRequest", [version_is_correct])

func loginRequest(_username: String, _password: String, peer_id):
	print("attempting to login: ", _username)
	# Get peer id and check for authentication
	
	#if not Server.peers[str(peer_id)].has("EngineRan"):
		#print("Player skipped engineRan")
		#Peers.kickPeer(peer_id)
		#return
	
	if not Global.GetValidNameString(_username):
		Peers.SendMessage(peer_id, "Invalid name. You may use numbers, letters, and spaces in between non-space characters.", 2)
		return
	
	var AuthenticationResult: Array = Database.AuthenticateUser(_username, _password)
	var Peer: PeerData = Peers.GetById(peer_id)
	var PeerByName: PeerData = Peers.GetByName(_username)
	
	# If authentication succeeded, add the peer to the active peers
	var DidLogin: bool = false
	
	if Peer.PeerId != -1:
		print("peer already online")
	
	print("authentication result:", AuthenticationResult[0], Peer.PeerId == -1, PeerByName.PeerId == -1)
	
	#if Server.peers[str(peer_id)].EngineRan:
		#if AuthenticationResult[1].permission_level != 5: # if its not a developer logging in
			#Peers.SendMessage(peer_id, "This account isnt authorized to play through the game engine!", 2)
			#return
	
	if Peer.PeerId != -1 or PeerByName.PeerId != -1:
		Peers.SendMessage(peer_id, "This account is already online!", 3)
		return
	
	if AuthenticationResult[0] == true:
		if typeof(AuthenticationResult[1]) != TYPE_DICTIONARY:
			Peers.SendMessage(peer_id, "Error logging in.", 2)
			return
		
		if AuthenticationResult[1].banned == 1:
			Peers.SendMessage(peer_id, "You have been banned from Pixel Planet Classic.", 2)
			return
		
		Peers.AddPeer(peer_id, AuthenticationResult[1].username, AuthenticationResult[1].id)
		DidLogin = true
		
		Peer = Peers.GetById(peer_id)
		if AuthenticationResult[1].inventory != "_NONE":
			Peer.Inventory = str_to_var(AuthenticationResult[1].inventory)
			
		Peer.Bits = AuthenticationResult[1].bits
		Peer.Email = AuthenticationResult[1].email
		
		if AuthenticationResult[1].clothes != "_NONE":
			Peer.Clothes = str_to_var(AuthenticationResult[1].clothes)
		
		Peer.PermissionLevel = AuthenticationResult[1].permission_level
		Peer.DatabaseId = AuthenticationResult[1].id
		Peer.Muted = AuthenticationResult[1].muted
		
		Global.server.rpc_id(peer_id, "returnEvent", "returnLoginRequest", [DidLogin, AuthenticationResult[1].username, AuthenticationResult[1].id])
		
	else:
		Peers.SendMessage(peer_id, "Error logging in. Is your username/password correct?", 2)

func registerRequest(_username: String, _password: String, peer_id):
	var address: String = Global.server.network.get_peer(peer_id).get_remote_address()
	
	if not Global.GetValidNameString(_username):
		Peers.SendMessage(peer_id, "Invalid name. You may use numbers, letters, and spaces in between non-space characters.", 2)
		return
	
	var RegistrationStatus: String = Database.RegisterUser(_username, _password, address)
	print("Registration status: ", RegistrationStatus)
	Peers.SendMessage(peer_id, RegistrationStatus, 5)

func worldDiveInRequest(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	
	
	if Peer.PeerId == -1: return
	
	if not Peer.CanJoin():
		Peers.SendMessage(peer_id, "Trying to join too fast!", 2)
		return
	
	# If the peer is already in a world, make them leave it
	if Peer.CurrentWorldName != "":
		Peer.LeaveWorld()
	
	if len(Worlds.ActiveWorlds) <= 0: 
		Peers.SendMessage(peer_id, "No active planets to dive into!", 2)
		return # no active worlds
	
	randomize()
	var random_index = randi_range(0, (Worlds.ActiveWorlds.size() - 1))
	
	var _world_name = Worlds.ActiveWorlds.keys()[random_index]
	
	var World: WorldData = Worlds.GetByName(_world_name, Peer)
	
	# Join user to world
	Peer.JoinWorld(_world_name)
	
	# Send world data to peer
	Global.server.rpc_id(peer_id, "returnEvent", "returnWorldJoinRequest", [World.IntoDict(true), Peer.Inventory, Peer.Bits, Peer.Clothes, Peer.PermissionLevel])

	World.SendToOtherPeers(peer_id, func(_peer_id: int):
		Global.server.rpc_id(_peer_id, "returnEvent", "returnPeerJoined", [Peer.PeerId, Peer.Name, Peer.Clothes, Peer.PermissionLevel, Peer.DatabaseId])
	)

func shopPurchaseRequest(_shop_id: String, peer_id):
	
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	
	var shop_purchase_data: Dictionary = Peer.PurchaseShopPack(_shop_id)
	
	if shop_purchase_data.success == true:
		Global.server.rpc_id(peer_id, "returnEvent", "returnShopPurchaseRequest", [shop_purchase_data.drops, true])
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[-100, -shop_purchase_data.price]])
		
		for drop in shop_purchase_data.drops:
			Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [drop])

func craftRequest(_item1_id: int, _item2_id: int, _item1_amount: int, _item2_amount: int, peer_id):
	
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	
	if _item1_amount <= 0 or _item2_amount <= 0: return
	
	if Peer.GetFreeInventorySlots() < 1:
		Peers.SendMessage(peer_id, "Your inventory is full.", 2)
		return
	
	var recipe: Dictionary = Data.GetRecipe(_item1_id, _item2_id, _item1_amount, _item2_amount)
	
	if recipe == {}: return
	if recipe.AMOUNT <= 0: return
	
	var item1_amount: int = recipe.INGREDIENT_1[1] * recipe.AMOUNT
	var item2_amount: int = recipe.INGREDIENT_2[1] * recipe.AMOUNT
	var result_amount: int = recipe.RESULT[1] * recipe.AMOUNT
	
	
	if Peer.InventoryHasAmount(_item1_id, item1_amount) and Peer.InventoryHasAmount(_item2_id, item2_amount):
		
		var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
		
		Peer.UpdateInventory(_item1_id, -item1_amount)
		Peer.UpdateInventory(_item2_id, -item2_amount)
		Peer.UpdateInventory(recipe.RESULT[0], result_amount)
		
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[_item1_id, -item1_amount]])
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[_item2_id, -item2_amount]])
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[recipe.RESULT[0], result_amount]])
		
		Global.server.rpc_id(peer_id, "returnEvent", "ShopPurchase", [[recipe.RESULT[0], result_amount]])
		
		# HANDLE QUEST HERE
		
		if not Peer.Quests.BhutansQuest["completed"]:
			var current_stuff = Peer.Quests.BhutansQuest["steps"][str(Peer.Quests.BhutansQuest["current_step"])]
			
			if current_stuff["ACTION"] == "CRAFT":
				if recipe.RESULT[0] == current_stuff["ID"]:
					current_stuff["CURRENT_AMOUNT"] += result_amount
					
					if current_stuff["CURRENT_AMOUNT"] >= current_stuff["AMOUNT"]:
						Peer.Quests.BhutansQuest["current_step"] += 1
						Peers.SendMessage(peer_id, "Step Complete! Check back with Bhutan", 0)
						Peer.SaveQuest()
		
		if Peer.Clothes == Peer.GetValidClothes(): return
		
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(_peer_id, "returnEvent", "returnEquipClothingRequest", [peer_id, Peer.GetValidClothes()])
		)

func grindRequest(_item_id: int, _item_amount: int, peer_id):
	
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	
	if _item_amount <= 0: return
	
	if Peer.GetFreeInventorySlots() < 1:
		Peers.SendMessage(peer_id, "Your inventory is full.", 2)
		return
	
	var recipe: Dictionary = Data.GetGrind(_item_id, _item_amount)
	
	if recipe == {}: return
	if recipe.AMOUNT <= 0: return
	
	var item_amount: int = recipe.INGREDIENT[1] * recipe.AMOUNT
	var result_amount: int = recipe.RESULT[1] * recipe.AMOUNT
	
	if Peer.InventoryHasAmount(_item_id, item_amount):
		
		var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
		
		Peer.UpdateInventory(_item_id, -item_amount)
		Peer.UpdateInventory(recipe.RESULT[0], result_amount)
		
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[_item_id, -item_amount]])
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[recipe.RESULT[0], result_amount]])
		
		Global.server.rpc_id(peer_id, "returnEvent", "ShopPurchase", [[recipe.RESULT[0], result_amount], false])
		
		if Peer.Clothes == Peer.GetValidClothes(): return
		
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(_peer_id, "returnEvent", "returnEquipClothingRequest", [peer_id, Peer.GetValidClothes()])
		)


func listItemRequest(_item_id: int, _item_amount: int, _price: int, _hours_active: int, peer_id):
	
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	
	# Check if item id is valid
	if _item_id <= 0: return
	if not Data.ItemData.has(str(_item_id)): return
	
	# Check if item amount is valid
	if _item_amount <= 0: return
	if not Peer.InventoryHasAmount(_item_id, _item_amount): return
	
	# Check if price is valid
	if _price <= 0 or _price > 999999999: return
	
	# Check if hours active is valid
	if _hours_active > 96 or _hours_active <= 0: return
	
	# Query marketplace database
	var success: bool = Database.CreateMarketplaceListing(_item_id, _item_amount, _price, _hours_active, Peer.DatabaseId)
	
	if success:
		
		Peer.UpdateInventory(_item_id, -_item_amount)
		
		var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
		
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[_item_id, -_item_amount]])
		
		if Peer.Clothes == Peer.GetValidClothes(): return
		
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(_peer_id, "returnEvent", "returnEquipClothingRequest", [peer_id, Peer.GetValidClothes()])
		)


func searchMarketplaceRequest(_item_name: String, _min_price: int, _max_price: int, _page_number: int, is_seller: bool, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	
	# Sanitize the shit
	if _min_price <= 0 or _min_price > 999999999 or _max_price <= 0 or _max_price > 999999999: return
	if _min_price > _max_price: return
	if _page_number < 0: return
	
	# Get database query results
	var search_result: Dictionary = Database.SearchMarketplaceListings(_item_name, _min_price, _max_price, _page_number, Peer.DatabaseId, is_seller) 
	print(search_result)
	# Send results to client
	if search_result.SUCCESS == true:
		Global.server.rpc_id(peer_id, "returnEvent", "returnSearchMarketplaceRequest", [search_result.LISTINGS])


func buyListingRequest(_listing_id: int, peer_id):
	
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	
	# Get the listing from id
	var listing_result: Dictionary = Database.GetListingFromId(_listing_id)

	# Check if user can purchase
	if listing_result.SUCCESS == false: return
	
	var listing: Dictionary = listing_result.LISTINGS[0]

	if Peer.Bits < listing.price and listing.seller_id != Peer.DatabaseId: return
	if listing.expiration <= Time.get_unix_time_from_system(): return
	
	if Peer.GetFreeInventorySlots() == 0 and not Peer.InventoryHas(listing.item_id): return
	
	var remove_result: bool = Database.RemoveListingWithId(_listing_id)

	# If the listing was removed successfully, make the peer purchase and give item
	if remove_result == true:
		if listing.seller_id != Peer.DatabaseId:
			Peer.UpdateInventory(-100, -listing.price)
			Peer.UpdateInventory(listing.item_id, listing.item_amount)
			print("buying")
			Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[-100, -listing.price]])
			Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[listing.item_id, listing.item_amount]])
			Global.server.rpc_id(peer_id, "returnEvent", "returnBuyListingRequest", [_listing_id])
			
		else:
			if listing.sold == 0:
				print("claiming back")
				Database.DeleteListingWithId(_listing_id)
				Peer.UpdateInventory(listing.item_id, listing.item_amount)
				Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[listing.item_id, listing.item_amount]])
				Global.server.rpc_id(peer_id, "returnEvent", "returnBuyListingRequest", [_listing_id])
				
			else:
				print("claiming bits")
				Database.DeleteListingWithId(_listing_id)
				Peer.UpdateInventory(-100, listing.price)
				Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[-100, listing.price]])
				Global.server.rpc_id(peer_id, "returnEvent", "returnBuyListingRequest", [_listing_id])

func setBlockMetadataRequest(position: Vector2i, metadata_info: Dictionary, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if not World.PeerCanEdit(Peer): return
	
	if World.IsInBounds(position) == false: return
	
	var block = World.GetBlock(position, 0)
	var block_item_data = Data.ItemData[str(block)]
	
	var metadata_set_success: bool = Global.MetadataCorrectnessCheck(block_item_data, metadata_info)
	
	
	if metadata_set_success == true:
		var metadata_set := World.SetBlockMetadata(position, metadata_info.METADATA, metadata_info.TYPE, Peer)
		print("metadata set: ", metadata_info.METADATA)
		if metadata_set != {}:
			World.SendToPeers(func(_peer_id: int):
				Global.server.rpc_id(_peer_id, "returnEvent", "returnSetBlockMetadataRequest", [position, metadata_set, true])
			)
			
			if Peer.Clothes == Peer.GetValidClothes():
				pass
			else:
				World.SendToPeers(func(_peer_id: int):
					Global.server.rpc_id(_peer_id, "returnEvent", "returnEquipClothingRequest", [peer_id, Peer.GetValidClothes()])
				)

func worldClaimRequest(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	if Peer.Bits < 1500: return
	
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if World.OwnerId == -1:
		Peer.Bits -= 1500
		World.OwnerId = Peer.DatabaseId
		World.OwnerName = Peer.Name
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[-100, -1500]])
		World.SendToPeers(func(_peer_id: int):
			if _peer_id != peer_id:
				Peers.SendMessage(_peer_id, "This world has been claimed by " + Peer.Name, 3)
			Global.server.rpc_id(_peer_id, "returnEvent", "returnWorldPermissionUpdate", [Peer.DatabaseId, Global.PERMISSIONS.WORLD_OWNER, Peer.Name])
		)
		
		if not Peer.Quests.BhutansQuest["completed"]:
			var current_stuff = Peer.Quests.BhutansQuest["steps"][str(Peer.Quests.BhutansQuest["current_step"])]
			
			if current_stuff["ACTION"] == "CLAIM":
				current_stuff["CURRENT_AMOUNT"] += 1
				
				if current_stuff["CURRENT_AMOUNT"] >= current_stuff["AMOUNT"]:
					Peer.Quests.BhutansQuest["completed"] = true
					Peers.SendMessage(peer_id, "Step Complete! Check back with Bhutan", 0)
					Peer.SaveQuest()

func itemDropRequest(_item_id: int, _amount: int, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	if _amount <= 0: return
	
	var item_data = Data.ItemData[str(_item_id)]
	
	if item_data.has("UNSELLABLE") and item_data.UNSELLABLE == true: return false
	
	if not Peer.InventoryHasAmount(_item_id, _amount): return # if doesnt have enough, refuse
	
	var infront_of_player_x: int
	
	if Peer.Direction: # facing right
		infront_of_player_x = -1
	else: # facing left
		infront_of_player_x = 1
	
	var drop_position = Global.worldToGrid(Peer.Position) + Vector2i(infront_of_player_x, 0)
	
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if not World.PeerCanEdit(Peer):
		Peers.SendMessage(Peer.PeerId, "You don't have the permission to drop here!", 2)
		return
	
	World.DropItem(_item_id, _amount, drop_position, peer_id)

func itemDropPickupRequest(_dropped_UID, peer_id):
	print("item pickup request")
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	
	#var player_block_position = (Vector2i(Peer.Position) / Vector2i(32, 32))
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if not World.PeerCanEdit(Peer):
		Peers.SendMessage(Peer.PeerId, "You don't have the permission to pick up this item!", 2)
		return
	
	World.itemDropPickup(_dropped_UID, peer_id)

func messageRequest(message: String, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	if Peer.CurrentWorldName == "": return
	
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if message.begins_with("/"):
		Commands.commandHandler(message, peer_id)
	else:
		
		message = Global.cleanText(message)
		
		if Peer.Muted != 1: # If the player is NOT muted
			World.SendToPeers(func(_peer_id: int):
				Global.server.rpc_id(_peer_id, "returnEvent", "returnMessageRequest", [Peer.Name, message, peer_id])
			)
		else:
			Peers.SendMessage(peer_id, "Cannot chat to others; You are muted!", 2)

func worldJoinRequest(_world_name: String, peer_id):
	# Get peer object
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if _world_name == "":
		Peers.SendMessage(peer_id, "Planet name can't be empty.", 2)
		return
	
	# If the name is longer than the max length, return
	if _world_name.length() > WorldData.MAX_WORLD_NAME_LENGTH:
		Peers.SendMessage(peer_id, "Planet name too long.", 2)
		return
	
	if not Global.GetValidNameString(_world_name):
		Peers.SendMessage(peer_id, "Invalid name. You may use numbers, letters, and spaces in between non-space characters.", 2)
		return
	
	_world_name = _world_name.to_lower()

	if Peer.PeerId == -1: return
	
	if not Peer.CanJoin(): return
	
	# If the peer is already in a world, make them leave it
	if Peer.CurrentWorldName != "":
		Peer.LeaveWorld()

	# Get world object
	var World: WorldData = Worlds.GetByName(_world_name, Peer)
	
	if not World.Valid:
		Peers.SendMessage(peer_id, "Max planet creation limit reached.", 2)
		return
	
	# Join user to world
	Peer.JoinWorld(_world_name)
	
	# Send world data to peer
	Global.server.rpc_id(peer_id, "returnEvent", "returnWorldJoinRequest", [World.IntoDict(true), Peer.Inventory, Peer.Bits, Peer.Clothes, Peer.PermissionLevel])

	World.SendToOtherPeers(peer_id, func(_peer_id: int):
		Global.server.rpc_id(_peer_id, "returnEvent", "returnPeerJoined", [Peer.PeerId, Peer.Name, Peer.Clothes, Peer.PermissionLevel, Peer.DatabaseId])
	)

func worldLeaveRequest(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	
	Peer.LeaveWorld()
	Global.server.rpc_id(peer_id, "returnEvent", "returnWorldLeaveRequest", [])

func placeBlockRequest(_block_id: int, _position: Vector2i, metadata_info: Dictionary, peer_id):
	
	# Get peer data
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	
	# If peer is not in a world, return
	if Peer.CurrentWorldName == "": return
	
	# If peer doesn't have block in inventory, return
	if not Peer.InventoryHas(_block_id): return
	
	# Get world data and set block
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if not World.PeerCanEdit(Peer): return
	
	if not AntiCheat.ValidEditDistance(_position, Peer.Position): return
	
	if World.SetBlock(_block_id, _position) == true:
		
		# HANDLE QUEST HERE
		if not Peer.Quests.BhutansQuest["completed"]:
			var current_stuff = Peer.Quests.BhutansQuest["steps"][str(Peer.Quests.BhutansQuest["current_step"])]
			
			if current_stuff["ACTION"] == "PLACE":
				if _block_id == current_stuff["ID"]:
					current_stuff["CURRENT_AMOUNT"] += 1
					
					if current_stuff["CURRENT_AMOUNT"] >= current_stuff["AMOUNT"]:
						Peer.Quests.BhutansQuest["current_step"] += 1
						Peers.SendMessage(peer_id, "Step Complete! Check back with Bhutan", 0)
						Peer.SaveQuest()
		
		
		if metadata_info != {}:
			var block = World.GetBlock(_position, 0)
			var block_item_data = Data.ItemData[str(block)]
	
			var metadata_set_success: bool = Global.MetadataCorrectnessCheck(block_item_data, metadata_info)
	
			if metadata_set_success == true:
				var metadata_set := World.SetBlockMetadata(_position, metadata_info.METADATA, metadata_info.TYPE, Peer)
				if metadata_set != {}:
					World.SendToPeers(func(_peer_id: int):
						Global.server.rpc_id(_peer_id, "returnEvent", "returnSetBlockMetadataRequest", [_position, metadata_set])
					)
		
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(_peer_id, "returnEvent", "returnPlaceBlockRequest", [_block_id, _position, peer_id])
		)
		
		Peer.UpdateInventory(_block_id, -1)
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[_block_id, -1]])

func breakBlockRequest(_position: Vector2i, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	
	var player_hand_id = Peer.Clothes.HAND
	var break_multiplier = 1
	
	
	if player_hand_id != -1:
		if Data.ItemData[str(player_hand_id)].has("BREAK_SPEED_MULT"):
			break_multiplier *= Data.ItemData[str(player_hand_id)]["BREAK_SPEED_MULT"]
	
	# If peer is not in a world, return
	if Peer.CurrentWorldName == "": return
	var can_break := Peer.CanBreak()
	print(can_break)
	if not can_break: return
	
	if not AntiCheat.ValidEditDistance(_position, Peer.Position): return
	
	# Get world data and break block
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if not World.PeerCanEdit(Peer): return
	
	var BreakResult: Dictionary = World.BreakBlock(_position, break_multiplier, peer_id)
	print(BreakResult)
	if BreakResult.Action == "BREAK":
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(_peer_id, "returnEvent", "breakBlockRequest", [BreakResult.BrokenValue, _position, peer_id])
		)

	elif BreakResult.Action == "DESTROY":
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(_peer_id, "returnEvent", "returnPlaceBlockRequest", [-1 , _position, peer_id])
		)
		
		# HANDLE QUEST HERE
		
		if not Peer.Quests.BhutansQuest["completed"]:
			var block_type = Data.ItemData[str(BreakResult.BlockID)]["TYPE"]
			
			var current_stuff = Peer.Quests.BhutansQuest["steps"][str(Peer.Quests.BhutansQuest["current_step"])]

			if current_stuff["ACTION"] == "BREAK":
				if block_type == current_stuff["TYPE"]:
					current_stuff["CURRENT_AMOUNT"] += 1
					
					if current_stuff["CURRENT_AMOUNT"] >= current_stuff["AMOUNT"]:
						Peer.Quests.BhutansQuest["current_step"] += 1
						Peers.SendMessage(peer_id, "Step Complete! Check back with Bhutan", 0)
						Peer.SaveQuest()
	
	if BreakResult.has("Drops"):
		Peer.UpdateInventory(BreakResult.Drops[0], BreakResult.Drops[1])
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [BreakResult.Drops])
		
		World.SendToPeers(func(_peer_id: int):
			Global.server.rpc_id(peer_id, "returnEvent", "returnBlockDrop", [peer_id, BreakResult.Drops])
		)

func updatePositionRequest(_position: Vector2, _current_state, _direction, _velocity, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	
	# If peer is not in a world, return
	if Peer.CurrentWorldName == "": return
	
	Peer.Position = _position
	Peer.MoveStamp = Time.get_unix_time_from_system()
	Peer.Direction = _direction
	
	Peer.client_velocity = _velocity
	
	if Peer.death and (Time.get_unix_time_from_system() - Peer.deathTimeStamp) >= 4:
		Peer.death = false
	
	if Peer.PreviousPosition == Vector2.ZERO:
		Peer.PreviousPosition = Peer.Position
		Peer.PreviousMoveStamp = Time.get_unix_time_from_system()
	
	if AntiCheat.AnalyzedPlayerData(_position, peer_id):
		Global.server.rpc_id(peer_id, "returnEvent", "returnSetPlayerPosition", [Peer.PreviousPosition])
		Peer.Position = Peer.PreviousPosition
	else:
		Peer.Position = _position
	
	Peer.PreviousPosition = Peer.Position
	Peer.PreviousMoveStamp = Time.get_unix_time_from_system()
	
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	World.SendToOtherPeers(peer_id, func(_peer_id: int):
		Global.server.rpc_id(_peer_id, "returnEvent", "returnUpdatePosition", [peer_id, Peer.Position, _current_state, _direction])
	)

func respawnRequest(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	Peer.Die()

func equipClothingRequest(_item_id: int, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	
	if Peer.CurrentWorldName == "": return
	if not Peer.InventoryHas(_item_id): return
	
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	var Equipment: Dictionary = Peer.Equip(_item_id)
	
	World.SendToPeers(func(_peer_id: int):
		Global.server.rpc_id(_peer_id, "returnEvent", "returnEquipClothingRequest", [peer_id, Equipment])
	)

func confirmEmailPrompt(email, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if not Global.isEmailValid(email):
		Peers.SendMessage(peer_id, "That email is an invalid email!", 2)
		return
	
	Peer.Email = email
	
	Database.SaveAccountInfo(Peer.Name, Peer.Email)
	
	Global.server.rpc_id(peer_id, "returnEvent", "returnEmailPrompt", [])
	Peers.SendMessage(peer_id, "Thank You! You have set up an email.", 4)

func rejectEmailPrompt(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.Email == "none":
		Peer.Email = "rejected"
	
	Database.SaveAccountInfo(Peer.Name, Peer.Email)
	
	Global.server.rpc_id(peer_id, "returnEvent", "returnEmailPrompt", [])
	Peers.SendMessage(peer_id, "You have rejected setting up an email.", 2)

func loadedWorldMenu(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.Email == "none":
		Global.server.rpc_id(peer_id, "returnEvent", "emailPrompt", [])

func worldSettingsBackground(id, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if not World.PeerCanEdit(Peer): return
	
	World.Background = clamp(id, 0, 4)
	
	World.SendToPeers(func(_peer_id: int):
		Global.server.rpc_id(_peer_id, "returnEvent", "backgroundUpdate", [World.Background])
	)

func worldSettingsLowGravity(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if not World.PeerCanEdit(Peer): return
	
	World.LowGravity = not World.LowGravity
	
	World.SendToPeers(func(_peer_id: int):
		Global.server.rpc_id(_peer_id, "returnEvent", "lowGravityUpdate", [World.LowGravity])
	)

func deathAcknowledgement(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	if Peer.death:
		Global.server.rpc_id(peer_id, "returnEvent", "returnSetPlayerPosition", [World.door_position * 32 + Vector2i(16, 16)])
		await get_tree().create_timer(1).timeout
		Peer.death = false
	

func requestPromotedPlanet(peer_id):
	if Global.server.promoted_planet == "":
		return
	
	Global.server.rpc_id(peer_id, "returnEvent", "returnPromotedPlanet", [Global.server.promoted_planet])

func requestBhutanQuestStatus(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	Global.server.rpc_id(peer_id, "returnEvent", "returnBhutanQuestStatus", [Peer.Quests["BhutansQuest"]])

func collectBhutanQuestReward(peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.Quests.BhutansQuest.completed && not Peer.Quests.BhutansQuest.collected:
		
		if Peer.GetFreeInventorySlots() < 1:
			Peers.SendMessage(peer_id, "Your inventory is full.", 2)
			return
		
		Peer.Quests.BhutansQuest.collected = true
		
		Peer.UpdateInventory(Peer.Quests.BhutansQuest.quest_reward[0], Peer.Quests.BhutansQuest.quest_reward[1])
		Global.server.rpc_id(peer_id, "returnEvent", "updateInventory", [[Peer.Quests.BhutansQuest.quest_reward[0], Peer.Quests.BhutansQuest.quest_reward[1]]])
		Peer.SaveQuest()
		Peers.SendMessage(peer_id, "You have finished Bhutan's Legendary Quest!", 0)
