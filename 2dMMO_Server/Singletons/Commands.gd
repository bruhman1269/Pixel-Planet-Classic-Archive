extends Node

@onready var server = get_parent()

enum {PLAYER=0, CREATOR=3, MODERATOR=4, DEVELOPER=5}

var admin_levels = {
	"give": DEVELOPER,
	"sundaereplacepassword": DEVELOPER,
	"giveall": DEVELOPER,
	"clearplanet": DEVELOPER,
	"promoteplanet": DEVELOPER,
	"saveserver": DEVELOPER,
	"changeperms": DEVELOPER,
	"summonall": DEVELOPER,
	"playercount": DEVELOPER,
	"summon": MODERATOR,
	"nickname": MODERATOR,
	"mute": MODERATOR,
	"unmute": MODERATOR,
	"ban": MODERATOR,
	"unban": MODERATOR,
	"spin": PLAYER,
	"admin": PLAYER,
	"pull": PLAYER,
}

func commandHandler(message, peer_id):
	
	var Peer: PeerData = Peers.GetById(peer_id)
	
	if Peer.PeerId == -1: return
	
	var params = message.split(" ")
	var command = params[0].split("/")[1]
	
	params.remove_at(0)
	
	if command in admin_levels:
		if not Peers.authenticateAdminLevel(admin_levels[command], Peer):
			#Global.server.rpc_id(peer_id, "returnEvent", "serverMessage", ["Sorry but this command doesn't exist.", "^1"])
			print("This player cannot execute such powerful command")
			return
	
	if self.has_method(command.to_lower()):
		var command_arg_count = Global.GetArgCount(command.to_lower(), self.get_method_list())
		params = Global.SplitArgs(params, command_arg_count-1)
		
		if params == [""]:
			params = []
		
		if len(params) < command_arg_count - 1:
			#Global.server.rpc_id(peer_id, "returnEvent", "serverMessage", ["Too few arguements for this command: `w" + command, "^1"])
			print("Too few arguements for this command: ", command)
			return
		
		params.insert(0, Peer)
		self.callv(command.to_lower(), params)
	
	else:
		#Global.server.rpc_id(peer_id, "returnEvent", "serverMessage", ["Sorry but this command doesn't exist.", "^1"])
		print("command doesnt exist")
		return

func summonall(peer: PeerData) -> void:
	for player_key in Peers.ActivePeerNames.keys():
		var World: WorldData = Worlds.GetByName(peer.CurrentWorldName, peer)
		var peer_to_summon: PeerData = Peers.GetByName(player_key)
		print(peer_to_summon)
		
		if peer_to_summon.PeerId == -1:
			continue

		if peer_to_summon == peer: # cant summon self
			continue

		if peer_to_summon.CurrentWorldName == peer.CurrentWorldName:
			peer_to_summon.PreviousPosition = peer.Position # set this because anticheat
			Global.server.rpc_id(peer_to_summon.PeerId, "returnEvent", "returnSetPlayerPosition", [peer.Position])
		else:
			Global.server.rpc_id(peer_to_summon.PeerId, "returnEvent", "returnSummonPlayer", [World.Name, peer.Position])
			peer_to_summon.PreviousPosition = peer.Position # set this because anticheat

func changeperms(peer: PeerData, player_name, rank) -> void:
	var peer_to_give: PeerData = Peers.GetByName(player_name)
	if peer_to_give.PeerId != -1:
		peer_to_give.PermissionLevel = rank

func give(peer: PeerData, player_name, item_id, amount) -> void:
	var peer_to_give: PeerData = Peers.GetByName(player_name)
	if peer_to_give.PeerId != -1:
		peer_to_give.UpdateInventory(int(item_id), int(amount))
		Global.SendInventoryUpdate(peer_to_give.PeerId, [item_id, amount])
	

func giveall(peer: PeerData, item_id, amount) -> void:
	for player_key in Peers.ActivePeerNames.keys():
		var peer_to_give: PeerData = Peers.GetByName(player_key)
		
		if peer_to_give.PeerId != -1:
			peer_to_give.UpdateInventory(item_id, amount)
			Global.SendInventoryUpdate(peer_to_give.PeerId, [item_id, amount])

func playercount(peer: PeerData) -> void:
	var player_count = len(Peers.ActivePeers)
	
	Peers.SendMessage(peer.PeerId, "There are currently " + str(player_count) + " players online!", 0)

func saveserver(peer: PeerData) -> void:
	print("DEVELOPER FORCE-SAVED SERVER INFORMATION")
	
	print("PRE-SAVE STAMP - " + str(Time.get_unix_time_from_system()))
	Global.server.SaveThread.start(Global.server.SaveServerInformation, Thread.PRIORITY_NORMAL)
	var result = Global.server.SaveThread.wait_to_finish()
	print("AFTER-SAVE STAMP - " + str(Time.get_unix_time_from_system()))
	
	Peers.SendMessage(peer.PeerId, "Server has saved all players & worlds that are currently active.", 4)


func mute(peer: PeerData, player_name) -> void:
	var peer_to_mute: PeerData = Peers.GetByName(player_name)

	if peer_to_mute.PeerId != -1:
		if peer_to_mute.PermissionLevel < Global.PERMISSIONS.MODERATOR:

			Database.SetMuted(player_name, true)
			peer_to_mute.Muted = 1

			Peers.SendMessage(peer.PeerId, peer_to_mute.Name + " has been muted!", 0)
			Peers.SendMessage(peer_to_mute.PeerId, "You have been muted!", 2)
		else:
			Peers.SendMessage(peer.PeerId, peer_to_mute.Name + " cant be muted!", 2)
	else:
		Database.SetMuted(player_name, true)
		Peers.SendMessage(peer.PeerId, player_name + " has been muted, but is offline; or may not exist!", 0)

func unmute(peer: PeerData, player_name) -> void:
	var peer_to_mute: PeerData = Peers.GetByName(player_name)

	if peer_to_mute.PeerId != -1:
		if peer_to_mute.Muted == 1: # is muted
			Database.SetMuted(player_name, false)
			peer_to_mute.Muted = 0
			Peers.SendMessage(peer.PeerId, peer_to_mute.Name + " has been unmuted.", 0)
			Peers.SendMessage(peer_to_mute.PeerId, "You have been unmuted.", 0)
		else:
			Peers.SendMessage(peer.PeerId, peer_to_mute.Name + " isnt muted!", 2)
	else:
		Database.SetMuted(player_name, false)
		Peers.SendMessage(peer.PeerId, player_name + " has been unmuted, but is offline; or may not exist!", 0)


func summon(peer: PeerData, player_name) -> void:
	var World: WorldData = Worlds.GetByName(peer.CurrentWorldName, peer)
	var peer_to_summon: PeerData = Peers.GetByName(player_name)

	if peer_to_summon.PeerId == -1:
		Peers.SendMessage(peer.PeerId, "This player is not online!", 2)
		return

	if peer_to_summon == peer: # cant summon self
		Peers.SendMessage(peer_to_summon.PeerId, "You can't summon yourself!", 2)
		return

	if peer_to_summon.CurrentWorldName == peer.CurrentWorldName:
		Peers.SendMessage(peer.PeerId, "Player was already in same world, so pulled instead.", 0)

		peer_to_summon.PreviousPosition = peer.Position # set this because anticheat
		Global.server.rpc_id(peer_to_summon.PeerId, "returnEvent", "returnSetPlayerPosition", [peer.Position])
		return

	Global.server.rpc_id(peer_to_summon.PeerId, "returnEvent", "returnSummonPlayer", [World.Name, peer.Position])
	peer_to_summon.PreviousPosition = peer.Position # set this because anticheat

func pull(peer: PeerData, player_name) -> void:
	var World: WorldData = Worlds.GetByName(peer.CurrentWorldName, peer)
	var peer_to_pull: PeerData = Peers.GetByName(player_name)

	if not World.isWorldClaimed(): # if not claimed, dont allow
		print("world not claimed")
		return

	if not World.PeerCanEdit(peer):
		print("player cant edit")
		return

	if peer_to_pull == peer: # cant pull self
		Peers.SendMessage(peer.PeerId, "You can't pull yourself!", 2)
		return

	if peer_to_pull.PeerId != -1 and peer_to_pull.CurrentWorldName == World.Name:

		peer_to_pull.PreviousPosition = peer.Position # set this because anticheat
		Global.server.rpc_id(peer_to_pull.PeerId, "returnEvent", "returnSetPlayerPosition", [peer.Position])
		Peers.SendMessage(peer_to_pull.PeerId, "You have been pulled by " + peer.Name, 0)

		Peers.SendMessage(peer.PeerId, "You pulled " + peer_to_pull.Name, 0)
	else:
		Peers.SendMessage(peer.PeerId, "You cant pull people out of thin air.. Try again once they exist", 2)

func ban(peer: PeerData, player_name) -> void:
	var peer_to_ban: PeerData = Peers.GetByName(player_name)

	if peer_to_ban.PeerId != -1:
		if peer_to_ban.PermissionLevel < Global.PERMISSIONS.MODERATOR:
			Global.server.kickPeer(peer_to_ban.PeerId)
			Database.SetBanned(player_name, true)

			Peers.SendMessage(peer.PeerId, "You have banned " + str(peer_to_ban.Name) + " indefinitely", 0)
		else:
			Peers.SendMessage(peer.PeerId, peer_to_ban.Name + " cannot be banned!", 0)

	else: # if player is not online // or does not exist
		var message = Database.SetBannedOffline(player_name)
		Peers.SendMessage(peer.PeerId, message, 0)

func unban(peer: PeerData, player_name) -> void:
	Database.SetBanned(player_name, false)
	Peers.SendMessage(peer.PeerId, "You have un-banned " + str(player_name), 0)


func spin(peer: PeerData) -> void:
	randomize()

	var peer_id: int = peer.PeerId
	var World: WorldData = Worlds.GetByName(peer.CurrentWorldName, peer)

	var message = "I spun a " + str(randi_range(0, 36))

	World.SendToPeers(func(_peer_id: int):
		Global.server.rpc_id(_peer_id, "returnEvent", "returnMessageRequest", [peer.Name, message, peer_id, true])
	)


func admin(peer: PeerData, player_name) -> void:
	var world: WorldData = Worlds.GetByName(peer.CurrentWorldName, peer)

	if world.PeerOwns(peer) == false:
		Peers.SendMessage(peer.PeerId, "Cannot add admin; you aren't the owner of this planet!", 3)
		return

	var peer_to_add: PeerData = Peers.GetByName(player_name)

	if peer_to_add.PeerId == -1:
		Peers.SendMessage(peer.PeerId, "The player you are trying to add must be in the planet with you.", 2)
		return

	if peer_to_add.CurrentWorldName != peer.CurrentWorldName:
		Peers.SendMessage(peer.PeerId, "The player you are trying to add must be in the planet with you.", 2)
		return

	if peer_to_add.DatabaseId == peer.DatabaseId:
		Peers.SendMessage(peer.PeerId, "You can't add yourself as an admin.", 2)
		return

	var result: WorldData.ADMIN_RESULT = world.AddAdmin(peer_to_add.DatabaseId)

	match result:
		WorldData.ADMIN_RESULT.SUCCESS:
			Peers.SendMessage(peer.PeerId, peer_to_add.Name + " is now an admin.", 5)
			Peers.SendMessage(peer_to_add.PeerId, "You are now an admin in this planet.", 5)
			world.SendToPeers(func(_peer_id: int):
				Global.server.rpc_id(_peer_id, "returnEvent", "returnWorldPermissionUpdate", [peer_to_add.DatabaseId, Global.PERMISSIONS.WORLD_ADMIN])
			)

		WorldData.ADMIN_RESULT.MAX_ADMINS:
			Peers.SendMessage(peer.PeerId, "You have reached the maximum amount of admins possible in this planet.", 2)

		WorldData.ADMIN_RESULT.ALREADY_ADMIN:
			world.RemoveAdmin(peer_to_add.DatabaseId)
			world.SendToPeers(func(_peer_id: int):
				Global.server.rpc_id(_peer_id, "returnEvent", "returnWorldPermissionUpdate", [peer_to_add.DatabaseId, Global.PERMISSIONS.NORMAL])
			)
			Peers.SendMessage(peer.PeerId, peer_to_add.Name + "'s admin rank has been removed!", 2)
			Peers.SendMessage(peer_to_add.PeerId, "Your admin rank has been removed!", 2)

func promoteplanet(peer: PeerData):
	var world: WorldData = Worlds.GetByName(peer.CurrentWorldName, peer)
	
	Global.server.promoted_planet = world.Name.to_upper()
	Peers.SendMessage(peer.PeerId, "%s is now the promoted planet!" % [world.Name.to_upper()], 4)

func sundaereplacepassword(peer: PeerData, username, password):
	
	if not Database.doesAccountExist(username):
		Peers.SendMessage(peer.PeerId, "Account does not exist.", 2)
		return
	
	Database.replacePassword(username, password)
	Peers.SendMessage(peer.PeerId, "Account password changed!", 0)
