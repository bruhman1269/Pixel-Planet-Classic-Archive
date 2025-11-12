extends CharacterBody2D

var item_id
var item_amount
var drop_UID = ""

var player = null
var move_towards = false

func LoadItem(item_id = item_id, item_amount = item_amount):
	self.global_position = Global.WorldNode.BlockTileMap.map_to_local(Global.getVector2CoordsFromUID(drop_UID))
	
	$ItemGlow/ItemIcon.frame = item_id + 1
	$ItemGlow/ItemIcon/Amount.text = str(item_amount)
	$ItemGlow/ItemIcon/ScaleAnimation.play("Scale")

func updateDroppedItem():
	$SFX.play()
	$ItemGlow/ItemIcon/ScaleAnimation.play_backwards("Scale")
	
	await $ItemGlow/ItemIcon/ScaleAnimation.animation_finished
	$ItemGlow/ItemIcon/Amount.text = str(item_amount)
	
	$ItemGlow/ItemIcon/ScaleAnimation.play("Scale")

func _on_pickup_area_area_entered(area):
	var parent = area.get_parent()
	
	if parent.is_in_group("Players") and parent.PeerId == -1:
		Server.ItemDropPickupRequest(drop_UID)

func initiatePickup(peer_id):
	$SFX.play()
	
	if not move_towards:
		
		if Server.self_peer_id == peer_id:
			player = Global.PlayerNode
		else:
			player = Global.WorldNode.WorldPeerManager.getPeerNode(peer_id)
		
		if player == null:
			self.queue_free()
			return
		
		
		move_towards = true
		$ItemGlow/ItemIcon/ScaleAnimation.play("Pickup")

func _process(delta):
	
	if move_towards and player != null:
		self.global_position = self.global_position.move_toward(player.global_position + Vector2(0, -15), 2.2)

func safeDespawn():
	self.visible = false
	$Despawn.start(randi_range(3, 10))

func _on_despawn_timeout():
	self.queue_free()
