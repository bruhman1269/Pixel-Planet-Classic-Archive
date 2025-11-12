extends Node

var MAX_SPEED = 10
var MAX_DISTANCE = 20.0
var MAX_TIME_DIFFERENCE = 1.0


func convertToTilePosition(position):
	return floor(position / 32)

func convertToRegularPosition(position):
	return (position * Vector2(32, 32))

func AnalyzedPlayerData(_position, peer_id):
	var Peer: PeerData = Peers.GetById(peer_id)
	
	var World: WorldData = Worlds.GetByName(Peer.CurrentWorldName, Peer)
	
	var current_position = _position
	var previous_position = Peer.PreviousPosition
	var current_stamp = Peer.MoveStamp
	var previous_stamp = Peer.PreviousMoveStamp
	
	if Peer.death:
		print("skip antchieat")
		return false
	
	var tiles_in_sight = lineofSight(convertToTilePosition(previous_position), convertToTilePosition(current_position))
	
	for position in tiles_in_sight:
		if World.IsBlock(position, 0):
			if World.BlockMetadata.has(str(position)):
				if World.BlockMetadata[str(position)].has("OPEN"): # if is door
					if not World.BlockMetadata[str(position)].OPEN: # if door is NOT open
						
						Peer.Die()
						print("death")
						
						return false # trigger anticheat
			else:
				Peer.Die()
	
	if Peer.client_velocity.length() > Peer.normal_velocity.length(): # SPEED hack prevention
		print("SPEED HACK")
		return true
	
	var block_distance_from_prior_position = convertToTilePosition(current_position).distance_to(convertToTilePosition(previous_position))
	
	if block_distance_from_prior_position > 2: # TELEPORT hack prevention
		if not Peer.death:
			print("TELEPORT HACK")
			return true
	
	### CHECKS FOR SPEED
	
	#var distance = current_position.distance_to(previous_position)
	#var time_difference = current_stamp - previous_stamp
#
	#if distance == 0:
		#return
	#
	#if distance > MAX_DISTANCE:
		#return false
	#
	#var speed = distance / time_difference
	#if speed > MAX_SPEED:
		#return false
	#
	#if time_difference > MAX_TIME_DIFFERENCE:
		#return false
	#
	#return true
	
func ValidEditDistance(placement, player_position):
	player_position = floor(player_position / 32)
	
	var distance = int(player_position.distance_to(placement))
	
	if distance <= 2: # 3 blocks away in any direction
		return true
	
	return false

func lineofSight(start_pos: Vector2, end_pos: Vector2) -> Array:
	var points = []

	var x0 = int(start_pos.x)
	var y0 = int(start_pos.y)
	var x1 = int(end_pos.x)
	var y1 = int(end_pos.y)

	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy

	while true:
		points.append(Vector2(x0, y0))

		if x0 == x1 and y0 == y1:
			break

		var e2 = 2 * err

		# Prioritize moving in the direction of the greatest change (dx vs dy)
		if e2 > -dy:
			err -= dy
			x0 += sx  # Move horizontally
		elif e2 < dx:
			err += dx
			y0 += sy  # Move vertically

	return points
