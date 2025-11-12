extends CharacterBody2D

@export_category("Platforming Vars")


@export_range(-1000, 0, -10) var JumpVelocity: float = -300
@export var JumpHoldTime: float = 0.17
@export var JumpAcceleration: float = 100
@export var HorizontalAcceleration: float = 50
@export var MaxHorizontalSpeed: float = 120
@export var MaxVerticalSpeed: float = 400
@export var CoyoteTime: float = 0.075

# CHANGE THESE LATER TO BE WORLD VARS
@export var Friction: float = 10
@export var WindResistance: float = 15
@export var Gravity: float = 20
#GLOBAL

@export var Hitting: bool = false

@onready var respawnSound = load("res://Assets/Audio/respawn.ogg")
@onready var Sprite = $Sprite
@onready var DropLabel = preload("res://Scenes/WorldScenes/DropLabel.tscn")
@onready var clothing_edit_sfx = $ClothingEditSFX

var admin_icon: Texture2D = load("res://Assets/Sprites/Misc/admin_icon.png")
var edit_icon: Texture2D = load("res://Assets/Sprites/Misc/edit_icon.png")
var influencer_icon: Texture2D = load("res://Assets/Sprites/Misc/influencer_icon.png")
var owner_icon: Texture2D = load("res://Assets/Sprites/Misc/owner_icon.png")
var pass_icon: Texture2D = load("res://Assets/Sprites/Misc/pass_icon.png")
var developer_icon: Texture2D = load("res://Assets/Sprites/Misc/developer_icon.png")

var knockbackAmount := Vector2(275.0, 300.0)

var last_hit: float = Time.get_ticks_usec()
var fps: int = 60 
var on_floor: bool = false
var can_idle: bool = true
var prev_pos = Vector2.ZERO
var flight_time: float = 0
var ref_flight_time: float = 0
var last_hit_time: int = 0
var can_fly: bool = true
var hit_velocity: Vector2
var is_dead: bool = false

var landing: bool = false

var jump_animated = false

var player_grid_pos

var PeerId: int = -1
var Username: String = ""

enum Directions {LEFT, RIGHT}

var LastDirectionMoved: int
var TimeLastJumped: float = Time.get_ticks_usec()
var LastCoyote: float = Time.get_ticks_usec()
var IsJumping: bool = false
var CanJump: bool = false
var CeilingHit: bool = false

var acum: float = 0
var health: float = 100


enum Animations {
	IDLE,
	WALKING,
	JUMPING,
	HURT,
	HIT,
	FALLING,
	DEATH
}

var animation_map = {
	"idle": Animations.IDLE,
	"walking": Animations.WALKING,
	"jumping": Animations.JUMPING,
	"hurt": Animations.HURT,
	"hit": Animations.HIT,
	"falling": Animations.FALLING,
	"death": Animations.DEATH
}

# Helper function to get the enum value from animation name
func animation_to_enum(animation_name: String) -> Animations:
	if animation_map.has(animation_name):
		return animation_map[animation_name]
	else:
		print("Unknown animation:", animation_name)
		return Animations.IDLE  # Default to IDLE or handle it as you see fit

# Helper function to get the animation name from enum value
func enum_to_animation(animation_enum: Animations) -> String:
	for key in animation_map.keys():
		if animation_map[key] == animation_enum:
			return key
	return ""  # Handle case when animation is not found


func go_to_entrance() -> void:
	self.position = Global.WorldNode.WorldBlockManager.entrance_pos * 32 + Vector2i(16, 16)
	self.velocity = Vector2.ZERO


func _ready() -> void:
	
	if PeerId == -1 and not is_instance_valid(Global.PlayerNode):
		Global.PlayerNode = self
		$Listener2D.make_current()
	
	gravityCheck()
	
	self.health = 100
	self.floor_block_on_wall = false

func gravityCheck():
	if Global.WorldData.LOW_GRAVITY:
		Gravity = 8
	else:
		Gravity = 20

func Update(_delta: float) -> void:
	#acum += delta
	#
	#if acum < 1.0/fps:
	#	return
	var MakeupIncrement: float = 1 + acum
	self.on_floor = self.is_on_floor()
	#acum = 0
	
	# Calculate if can jump
	if on_floor:
		LastCoyote = Time.get_ticks_usec()
		CanJump = true
	elif CanJump:
		if (Time.get_ticks_usec() - LastCoyote) / 1000000 > CoyoteTime:
			CanJump = false
		
	# Get horizontal movement from input axis strengths
	var horizontal_movement: float = (Input.get_action_strength("right") - Input.get_action_strength("left")) * HorizontalAcceleration
	
	if PlayerState.current_state != PlayerState.STATE_TYPE.WORLD or self.is_dead:
		horizontal_movement = 0
	
	if Input.is_action_pressed("up") and PlayerState.current_state == PlayerState.STATE_TYPE.WORLD and not self.is_dead:
		
		if CanJump:
			if not IsJumping:
				can_idle = true
				CeilingHit = false
				flight_time -= _delta * 20
				CanJump = false
				IsJumping = true
				TimeLastJumped = Time.get_ticks_usec()
				self.velocity.y = JumpVelocity
				$JumpSFX.pitch_scale = randf_range(1, 1.3)
				$JumpSFX.play()
				
				if Global.SelfData.Clothes.BACK != -1:
					
					var wing_id = Global.SelfData.Clothes.BACK
					
					if not Data.ItemData[str(wing_id)].has("LAUNCH_VFX"): return
					
					var LAUNCH_VFX = "res://Assets/Sprites/VFX/" + Data.ItemData[str(wing_id)].LAUNCH_VFX
					
					var sprite = load("res://Scenes/WorldScenes/vfx.tscn").instantiate()
					sprite.texture = load(LAUNCH_VFX)
					
					var sprite_file_size = sprite.texture.get_size()
					
					var HFrames = sprite_file_size.x / 64
					var VFrames = sprite_file_size.y / 64
					
					sprite.hframes = HFrames
					sprite.vframes = VFrames
					
					sprite.max_frames = (HFrames * VFrames) - 1
					
					sprite.position = self.position - Vector2(0, 2)
					Global.SpecialAnimationsNode.add_child(sprite)
		
		elif (Time.get_ticks_usec() - TimeLastJumped < JumpHoldTime * 1000000 and IsJumping and not CeilingHit) or (self.flight_time > 0 and self.can_fly):
			self.velocity.y = JumpVelocity + (1 / (Time.get_ticks_usec() - TimeLastJumped) / 1000000) * JumpAcceleration
			flight_time -= _delta
			
			if Input.is_action_just_pressed("up"):
				flight_time -= _delta * 4
		
		elif self.flight_time <= 0 and self.ref_flight_time > 0:
			if self.velocity.y > MaxVerticalSpeed / 2:
				self.velocity.y /= 2
		
	else:
		if IsJumping:
			IsJumping = false
	
	# Apply movement components to movement vector
	if horizontal_movement != 0:
		self.velocity.x = clamp(self.velocity.x + horizontal_movement, -MaxHorizontalSpeed, MaxHorizontalSpeed)
		
		if horizontal_movement > 0:
			LastDirectionMoved = Directions.RIGHT
		else:
			LastDirectionMoved = Directions.LEFT
	
	# Apply friction & wind resistance
	if self.velocity.x > horizontal_movement:
		if self.on_floor:
			self.velocity.x = clamp(self.velocity.x - (Friction + WindResistance), 0, MaxHorizontalSpeed)
		else:
			self.velocity.x = clamp(self.velocity.x - WindResistance, 0, MaxHorizontalSpeed)
	elif self.velocity.x < -horizontal_movement:
		if self.on_floor:
			self.velocity.x = clamp(self.velocity.x + (Friction + WindResistance), -MaxHorizontalSpeed, 0)
		else:
			self.velocity.x = clamp(self.velocity.x + WindResistance, -MaxHorizontalSpeed, 0)
	
	# Apply gravity
	if not self.on_floor or self.get_floor_angle() > 1.5:
		self.velocity.y += Gravity
	
	elif self.on_floor:
		TimeLastJumped = Time.get_ticks_usec()
	
	if self.on_floor:
		flight_time = ref_flight_time
	
	# HANDLE CEILING COLLISIONS
	if self.is_on_ceiling() and flight_time <= 0:
		CeilingHit = true
		self.velocity.y = 1
	
	# Apply the makeup increment
	
	
	var overlapping_hurt = $HurtCollider.get_overlapping_areas()
	if len(overlapping_hurt) > 0:
		var hurtbox = overlapping_hurt[0]
		
		var player_floor: Vector2i = floor(self.position / 32)
		var left_tile = Global.WorldNode.BlockTileMap.get_cell_source_id(0, player_floor - Vector2i(1, 0))
		var right_tile = Global.WorldNode.BlockTileMap.get_cell_source_id(0, player_floor + Vector2i(1, 0))
		var up_tile = Global.WorldNode.BlockTileMap.get_cell_source_id(0, player_floor - Vector2i(0, 1))
		var bottom_tile = Global.WorldNode.BlockTileMap.get_cell_source_id(0, player_floor + Vector2i(0, 1))
		
		if left_tile != -1:
			var item_data = Data.ItemData[str(left_tile)]
			if item_data.has("SPECIALTY") and item_data.SPECIALTY == "HURT":
				left_tile = false
		else:
			left_tile = false
		if right_tile != -1:
			var item_data = Data.ItemData[str(right_tile)]
			if item_data.has("SPECIALTY") and item_data.SPECIALTY == "HURT":
				right_tile = false
		else:
			right_tile = false
		if up_tile != -1:
			var item_data = Data.ItemData[str(up_tile)]
			if item_data.has("SPECIALTY") and item_data.SPECIALTY == "HURT":
				up_tile = false
		else:
			up_tile = false
		if bottom_tile != -1:
			var item_data = Data.ItemData[str(bottom_tile)]
			if item_data.has("SPECIALTY") and item_data.SPECIALTY == "HURT":
				bottom_tile = false
		else:
			bottom_tile = false
		
		print("left: ", left_tile)
		print("right: ", right_tile)
		print("up: ", up_tile)
		print("bottom: ", bottom_tile)
		
		var can_collide: bool = true
		if self.position.x > hurtbox.position.x and self.position.y > hurtbox.position.y and typeof(left_tile) == TYPE_INT and typeof(up_tile) == TYPE_INT:
			can_collide = false
		elif self.position.x < hurtbox.position.x and self.position.y > hurtbox.position.y and typeof(up_tile) == TYPE_INT and typeof(right_tile) == TYPE_INT:
			can_collide = false
		elif self.position.x < hurtbox.position.x and self.position.y < hurtbox.position.y and typeof(bottom_tile) == TYPE_INT and typeof(right_tile) == TYPE_INT:
			can_collide = false
		elif self.position.x > hurtbox.position.x and self.position.y < hurtbox.position.y and typeof(left_tile) == TYPE_INT and typeof(bottom_tile) == TYPE_INT:
			can_collide = false
		
		if can_collide:
			
			if not self.is_dead:
				self.last_hit_time = Time.get_ticks_msec()
				self.health -= 25
			
				Global.WorldNode.UpdateHealthBar()
			
			if self.position.x - 11 > hurtbox.position.x:
				self.velocity.x = MaxHorizontalSpeed
				self.position.x += 3
			else:
				self.velocity.x = -MaxHorizontalSpeed
				self.position.x -= 3
			
			if self.position.y - 11 > hurtbox.position.y:
				self.velocity.y = MaxVerticalSpeed
				self.position.y += 3
			else:
				self.velocity.y = -MaxHorizontalSpeed
				self.position.y -= 3
			hit_velocity.x = clamp(self.velocity.x * 100000000000, -MaxHorizontalSpeed, MaxHorizontalSpeed) * 1.2
			hit_velocity.y = clamp(self.velocity.y * 100000000000, -MaxVerticalSpeed, MaxVerticalSpeed) / 2
		
	if Time.get_ticks_msec() - self.last_hit_time < 120:
		self.velocity = hit_velocity
		self.can_fly = false
	else:
		self.can_fly = true
		self.velocity.x = clamp(self.velocity.x * MakeupIncrement, -MaxHorizontalSpeed, MaxHorizontalSpeed)
		self.velocity.y = clamp(self.velocity.y * MakeupIncrement, -MaxVerticalSpeed, MaxVerticalSpeed)
	
	if Time.get_ticks_msec() - self.last_hit_time >= 5000 and not self.is_dead:
		self.health = 100
		Global.WorldNode.UpdateHealthBar()
	
	if self.health <= 0:
		self.Die(true)
	
	#if self.on_floor:
	#	var platform_collisions = $PlatformCollider.get_overlapping_areas()
	#	if len(platform_collisions) > 0:
	#		self.position.y = platform_collisions[0].position.y - 14.1
	#		self.velocity.y = 0
		
	self.move_and_slide()
	
	if $RayCast2D.is_colliding() and not self.is_dead and PlayerState.current_state == PlayerState.STATE_TYPE.WORLD :
		var collision = $RayCast2D.get_collider()
		if is_instance_valid(collision) and collision.has_method("disable") and Input.is_action_pressed("down"):
			collision.disable()
	
	if $RayCast2D2.is_colliding() and not self.is_dead and PlayerState.current_state == PlayerState.STATE_TYPE.WORLD :
		var collision = $RayCast2D2.get_collider()
		if is_instance_valid(collision) and collision.has_method("disable") and Input.is_action_pressed("down"):
			collision.disable()
	
	# Animate
	if LastDirectionMoved == Directions.LEFT:
		$Sprite.flip_h = true
	elif LastDirectionMoved == Directions.RIGHT:
		$Sprite.flip_h = false
	
	if self.velocity.y == 0 and Time.get_ticks_usec() - last_hit >= 250000 and not self.is_dead:
		if abs(abs(self.prev_pos.x) - abs(self.position.x)) <= 0.1 and is_on_floor():
			$AnimationPlayer.play("idle")
			
		elif not self.is_dead:
			$AnimationPlayer.play("walking")
	
	if self.velocity.y >= 0 and not self.is_dead and not self.is_on_floor(): #and len($PlatformCollider.get_overlapping_areas()) == 0:
		if $AnimationPlayer.current_animation != "falling":
			$AnimationPlayer.play("falling")

	elif not self.on_floor and not self.is_dead: #and len($PlatformCollider.get_overlapping_areas()) == 0:

		$AnimationPlayer.play("jumping")
		
	if self.is_dead and $AnimationPlayer.current_animation != "death":
		$AnimationPlayer.play("death")
	

	if velocity.x != 0 and self.on_floor and $AnimationPlayer.current_animation == "walking":
		if not $Footstep.playing:
			
			$Footstep.pitch_scale = randf_range(0.85, 1.2)
			$Footstep.play()
	elif $Footstep.playing:
		$Footstep.stop()
	
	
	if self.on_floor:
		if landing:
			$LandSFX.play()
			$Footstep.pitch_scale = randf_range(1, 1.4)
			landing = false
	else:
		if !landing:
			landing = true


	#if Time.get_ticks_msec() - self.last_hit_time < 120 and $AnimationPlayer.current_animation != "hurt":
	#	$AnimationPlayer.play("hurt")
	
	if Global.WorldData:
		if self.position.x < 6 or self.position.x > Global.WorldData.WorldSize.x * 32 - 6:
			self.position.x = clamp(self.position.x, 6, Global.WorldData.WorldSize.x * 32 - 6)
			self.velocity.x = 0
		if self.position.y < 0 or self.position.y > Global.WorldData.WorldSize.y * 32:
			self.position.y = clamp(self.position.y, 0, Global.WorldData.WorldSize.y * 32)
			self.velocity.y = 0
	
	prev_pos = self.position
	
	
	

func _process(delta: float) -> void:
	$Clothing/Back.frame = $Sprite.frame
	$Clothing/Pants.frame = $Sprite.frame
	$Clothing/Shoes.frame = $Sprite.frame
	$Clothing/Shirt.frame = $Sprite.frame
	$Clothing/Hair.frame = $Sprite.frame
	$Clothing/Face.frame = $Sprite.frame
	$Clothing/Hat.frame = $Sprite.frame
	$Clothing/Hand.frame = $Sprite.frame
	$Clothing/Tool.frame = $Sprite.frame
	for cloth in $Clothing.get_children():
		cloth.flip_h = $Sprite.flip_h
	
	player_grid_pos = Global.WorldNode.BlockTileMap.local_to_map(self.position)

func UpdateAsPeer(_position: Vector2, _current_state, _direction, _peer_id) -> void:
	PeerId = _peer_id
	#if abs(abs(_position.x) - abs(self.position.x)) > 0.1:
		#if _position.x > self.position.x:
			#$Sprite.flip_h = false
		#elif _position.x < self.position.x:
			#$Sprite.flip_h = true
	
	
	#if _position.x == prev_pos.x:
		#$AnimationPlayer.play("idle")
	#else:
		#$AnimationPlayer.play("walking")
	#
	#if _position.y > self.position.y:
		#$AnimationPlayer.play("jumping")
	#elif _position.y < self.position.y:
		#$AnimationPlayer.play("falling")
		
	$Sprite.flip_h = _direction
	$AnimationPlayer.play(enum_to_animation(_current_state))
	
	create_tween().tween_property(self, "position", _position, 0.075)
	prev_pos = _position
	
	if enum_to_animation(_current_state) == "jumping" and ($LandCast.is_colliding() or $LandCast2.is_colliding() or $LandCast3.is_colliding()):
		if Global.WorldPeers[_peer_id].Clothes.BACK != -1:
			
			var wing_id = Global.WorldPeers[_peer_id].Clothes.BACK
			
			if not Data.ItemData[str(wing_id)].has("LAUNCH_VFX"): return
			
			var LAUNCH_VFX = "res://Assets/Sprites/VFX/" + Data.ItemData[str(wing_id)].LAUNCH_VFX
			
			var sprite = load("res://Scenes/WorldScenes/vfx.tscn").instantiate()
			sprite.texture = load(LAUNCH_VFX)
			
			var sprite_file_size = sprite.texture.get_size()
			
			var HFrames = sprite_file_size.x / 64
			var VFrames = sprite_file_size.y / 64
			
			sprite.hframes = HFrames
			sprite.vframes = VFrames
			
			sprite.max_frames = (HFrames * VFrames) - 1
			
			sprite.position = self.position - Vector2(0, 2)
			Global.SpecialAnimationsNode.add_child(sprite)




#func Animate() -> void:
#	if LastDirectionMoved == Directions.LEFT:
#		$Sprite.flip_h = true
#	elif LastDirectionMoved == Directions.RIGHT:
#		$Sprite.flip_h = false
#
#	if self.velocity.y == 0 and Time.get_ticks_usec() - last_hit >= 250000:
#		if abs(abs(self.prev_pos.x) - abs(self.position.x)) <= 0.1:
#			$AnimationPlayer.play("idle")
#		else:
#			$AnimationPlayer.play("walking")
#
#	if self.velocity.y > 0:
#		if $AnimationPlayer.current_animation != "falling":
#			$AnimationPlayer.play("falling")
#	elif not self.is_on_floor():
#		$AnimationPlayer.play("jumping")

func Die(send_to_door = false):
	self.health = 100
	self.is_dead = true
	await Global.WorldNode.get_tree().create_timer(2).timeout
	if is_instance_valid(Global.WorldNode):
		if send_to_door:
			self.go_to_entrance()
		playSound(respawnSound)
		self.is_dead = false
		Global.WorldNode.UpdateHealthBar()


func Hit() -> void:
	if $AnimationPlayer.current_animation != "jumping" and $AnimationPlayer.current_animation != "falling":
		last_hit = Time.get_ticks_usec()
		
		if $AnimationPlayer.current_animation != "hit":
			$AnimationPlayer.play("hit")

func SetName(_name: String, permission_level: int, peer_data: PeerData) -> void:
	$NameLabel.text = "[center]"
	#$NameLabel.append_text("[center]" + _name + "[/center]")
	self.Username = _name
	
	if peer_data.is_owner:
		$NameLabel.text += "[img]" + "res://Assets/Sprites/Misc/owner_icon.png" + "[/img]"
	elif peer_data.is_admin:
		$NameLabel.text += "[img]" + "res://Assets/Sprites/Misc/admin_icon.png" + "[/img]"
	
	match permission_level:
		Global.PERMISSIONS.DEVELOPER:
			$NameLabel.text += "[img]" + "res://Assets/Sprites/Misc/developer_icon.png" + "[/img]"
		Global.PERMISSIONS.MODERATOR:
			$NameLabel.text += "[img]" + "res://Assets/Sprites/Misc/moderator_icon.png" + "[/img]"
		Global.PERMISSIONS.CREATOR:
			$NameLabel.text += "[img]" + "res://Assets/Sprites/Misc/influencer_icon.png" + "[/img]"
	
	$NameLabel.text += _name


func CreateDrop(_drop_data: Array) -> void:
	var NewDropLabel = DropLabel.instantiate()
	Global.WorldNode.BlockDrops.add_child(NewDropLabel)
	NewDropLabel.Summon(_drop_data[0], _drop_data[1], self)

func SetClothing(_clothing_dict: Dictionary, loading: bool = false) -> void:
	
	if not loading:

		clothing_edit_sfx.play()

	
	self.flight_time = 0
	self.ref_flight_time = 0
	
	$Clothing/Back.texture = null
	$Clothing/Pants.texture = null
	$Clothing/Shoes.texture = null
	$Clothing/Shirt.texture = null
	$Clothing/Hair.texture = null
	$Clothing/Hat.texture = null
	$Clothing/Face.texture = null
	$Clothing/Hand.texture = null
	$Clothing/Tool.texture = null
	
	for clothing_id in _clothing_dict.values():
		
		if clothing_id == -1: continue
		
		var item_data = Data.ItemData[str(clothing_id)]
		
		if not item_data.has("PATH"):
			return
		var resource = load("res://Assets/Sprites/Clothing/" + item_data.PATH)
		
		match item_data.PLACE:
			
			"BACK":
				$Clothing/Back.texture = resource
			"PANTS":
				$Clothing/Pants.texture = resource
			"SHOES":
				$Clothing/Shoes.texture = resource
			"SHIRT":
				$Clothing/Shirt.texture = resource
			"HAIR":
				$Clothing/Hair.texture = resource
			"HAT":
				$Clothing/Hat.texture = resource
			"HAND":
				$Clothing/Hand.texture = resource
			"TOOL":
				$Clothing/Tool.texture = resource
			"FACE":
				$Clothing/Face.texture = resource
		
		if item_data.has("SPECIALTY"):
			
			match item_data.SPECIALTY:
			
				"FLIGHT":
					#self.flight_time = item_data.FLIGHT_TIME
					self.ref_flight_time = item_data.FLIGHT_TIME
		
	var new_smoke = Global.WorldNode.Smoke.instantiate()
	new_smoke.position = self.position
	Global.WorldNode.Particles.add_child(new_smoke)

func SwingSpecialAnimation(_clothing_dict: Dictionary, _position):
	
	for clothing_id in _clothing_dict.values():
		
		if clothing_id == -1: continue
		
		var item_data = Data.ItemData[str(clothing_id)]
		
		if not item_data.has("SWING_SPECIAL_ANIMATION"): continue
		print("PLAYER HAS ITEM THAT HAS SWING SPECIAL ANIMATION")
		
		var instance = load("res://Scenes/ClothingEffects/" + item_data.SWING_SPECIAL_ANIMATION).instantiate()
		
		instance.global_position = self.position
		instance.destination = Vector2(_position) * Vector2(32, 32) + Vector2(16, 16)#Global.WorldNode.BlockTileMap.map_to_local(_position)
		
		var direction = self.global_position - instance.destination
		
		print("direction %s" % [rad_to_deg(atan2(direction.y, direction.x))])
		
		instance.rotation_degrees = rad_to_deg(atan2(direction.y, direction.x))
		
		Global.SpecialAnimationsNode.add_child(instance)
		
		instance._ready = true
func messageSent(message, forced_by_server = false):
	
	for timer in $ChatBubble/Timers.get_children():
		timer.queue_free()
	
	if forced_by_server:
		$ChatBubble.set_modulate(Color(0, 1, 0.384))
	else:
		$ChatBubble.set_modulate(Color(1, 1, 1))
	
	var minTime = 3.0  # Minimum time in seconds for bubble
	var maxTime = 10.0  # Maximum time in seconds for bubble
	
	var timer = Timer.new()
	$ChatBubble/Timers.add_child(timer)
	timer.start(clamp(len(message) * 0.5, minTime, maxTime))
	
	$ChatBubble.text = message
	$ChatBubble.visible = true
	$ChatBubble/AnimationPlayer.play("Zoom")
	
	await timer.timeout
	
	$ChatBubble/AnimationPlayer.play_backwards("Zoom")
	await $ChatBubble/AnimationPlayer.animation_finished
	$ChatBubble.visible = false
	$ChatBubble.text = ""
	
func _on_chat_timer_timeout():
	pass
	#$ChatBubble/AnimationPlayer.play_backwards("Zoom")
	#
	#await $ChatBubble/AnimationPlayer.animation_finished
	#
	#$ChatBubble.visible = false
	#$ChatBubble.text = ""

func playSound(sound_path):
	$AudioStreamPlayer.stream = AudioStreamOggVorbis
	$AudioStreamPlayer.stream = sound_path
	$AudioStreamPlayer.play()

func bounce(amount, bounceLocation):
	
	if self.position.y - 11 > bounceLocation.y:
		return
	else:
		self.velocity.y = -MaxHorizontalSpeed * 3
	
	if self.position.x - 11 > bounceLocation.x:
		self.velocity.x = MaxHorizontalSpeed
		#self.position.x += 3
	else:
		self.velocity.x = -MaxHorizontalSpeed
		#self.position.x -= 3
