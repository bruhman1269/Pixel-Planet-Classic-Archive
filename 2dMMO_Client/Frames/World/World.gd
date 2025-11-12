extends Node2D

@onready var BlockTileMap = $BlockTiles
@onready var BackgroundTileMap = $BackgroundTiles
@onready var CrackBlockTileMap = $CrackBlockTiles
@onready var CrackBackgroundTileMap = $CrackBackgroundTiles
@onready var Player = $Player
@onready var Peers = $Peers
@onready var Dropped = $Dropped
@onready var GUIRect = $GUI/ColorRect
@onready var Inventory = $GUI/Inventory
@onready var Shop = $GUI/Shop
@onready var Rewards = $GUI/Rewards
@onready var Pause = $GUI/PauseMenu
@onready var Settings = $GUI/SettingsMenu
@onready var BhutanQuest = $GUI/BhutanQuest
@onready var PlanetMenu = $GUI/PlanetMenu
@onready var Crafting = $GUI/Crafting
@onready var ItemFrame = $GUI/ItemFrame
@onready var ItemAdder = $GUI/ItemAdder
@onready var Dropping = $GUI/Dropping
@onready var Grinding = $GUI/Grinding
@onready var BlockDrops = $BlockDrops
@onready var Grid = $Grid
@onready var Particles = $Particles
@onready var HUD = $HUD
@onready var ItemFilters = $GUI/ItemFilters
@onready var Marketplace = $GUI/Marketplace
@onready var SellItem = $GUI/SellItem
@onready var Chat = $GUI/Chat
@onready var TextAdder = $GUI/TextAdder
@onready var SignBubble = $SignBubble
@onready var ClaimPlanet = $GUI/ClaimPlanet
@onready var popup = $HUD/Popup

@onready var UpdateTileSound = preload("res://Scenes/WorldScenes/tile_update_sound.tscn")

@onready var DroppedItem = preload("res://Frames/DroppedItem/dropped_item.tscn")
@onready var PlatformArea = preload("res://Scenes/WorldScenes/PlatformArea.tscn")
@onready var BouncerArea = preload("res://Scenes/WorldScenes/BouncerArea.tscn")
@onready var DoorCollision = preload("res://Scenes/WorldScenes/DoorCollision.tscn")
@onready var FramedItem = preload("res://Scenes/WorldScenes/FramedItem.tscn")
@onready var WorldPeerManager = preload("res://Scenes/WorldScenes/WorldPeerManager.gd").new()
@onready var WorldBlockManager = preload("res://Scenes/WorldScenes/WorldBlockManager.gd").new()
@onready var WorldGUIManager = preload("res://Scenes/WorldScenes/WorldGUIManager.gd").new()
@onready var HurtArea = preload("res://Scenes/WorldScenes/HurtArea.tscn")
@onready var Smoke = preload("res://Scenes/WorldScenes/Effects/Smoke.tscn")
@onready var camera = $Camera
var cameraZoomRange := Vector2(1,4)
var currentCameraZoom := 1
var cameraZoomSpeed := 0.1

var should_update_grid: bool = false
var current_gui = null
var prompting_gui = null

var has_planet_access = false

func _ready():
	Global.WorldNode = self
	Global.PeersNode = $Peers
	Global.SpecialAnimationsNode = $SpecialAnimations
	PlayerState.current_state = PlayerState.STATE_TYPE.WORLD
	WorldBlockManager.SetTilemaps(BlockTileMap, BackgroundTileMap, CrackBlockTileMap, CrackBackgroundTileMap)
	WorldBlockManager.LoadBlockArray()
	WorldPeerManager.Init(multiplayer.get_unique_id())
	WorldPeerManager.LoadPeers()
	WorldGUIManager.ConnectViewportStuff(get_viewport())
	ClampCamera()
	SendPosition()
	Inventory.SetSlots()
	Inventory.SetClothesSlots(Global.SelfData.Clothes)
	Player.SetName(Global.Username, Global.SelfData.PermissionLevel, Global.SelfData)
	Player.SetClothing(Global.SelfData.Clothes, true)
	Player.go_to_entrance()
	HUD.display_bits(Global.SelfData.Bits)
	
	Settings.change_sound(Global.WorldData.Background)
	
	$LoadScreen.game_loaded = true
	
	for slot in Global.WorldData.DroppedData:
		for dropped_data in Global.WorldData.DroppedData[slot]["dropped"]:
			DroppedItemUpdate(dropped_data, true)

	Global.WorldData.DroppedData.clear()
	
	if Server.summon_position != Vector2(-2000, -2000): # means if someone summoned
		Global.PlayerNode.position = Server.summon_position
		Server.summon_position = Vector2(-2000, -2000)

func _process(_delta) -> void:
	SignBubble.position = get_global_mouse_position() + Vector2(15, 5)

	if PlayerState.current_state == PlayerState.STATE_TYPE.WORLD:
		WorldBlockManager.Update(self.get_global_mouse_position(), should_update_grid, Player.position)

	if should_update_grid:
		Grid.Update(WorldBlockManager.cur_tilemap, Player.position, self.get_global_mouse_position())
	else:
		Grid.Invis()


func _physics_process(_delta):
	Player.Update(_delta)

	$Camera.position = Player.position
	camera.zoom.x = move_toward(camera.zoom.x, currentCameraZoom, cameraZoomSpeed)
	camera.zoom.y = move_toward(camera.zoom.y, currentCameraZoom, cameraZoomSpeed)


func _input(_event: InputEvent) -> void:
	if WorldGUIManager.typing == false:
		if Input.is_action_just_pressed("inventory"): #and Inventory.can_open and (not self.current_gui or self.current_gui.can_open):
			Inventory.prompting = false
			WorldGUIManager.ChangeGui(Inventory)
			Inventory.update_bits()


		elif Input.is_action_just_pressed("shop"): #and Shop.can_open and (not self.current_gui or self.current_gui.can_open):
			WorldGUIManager.ChangeGui(Shop)


		elif Input.is_action_just_pressed("marketplace"): #and Marketplace.can_open and (not self.current_gui or self.current_gui.can_open):
			WorldGUIManager.ChangeGui(Marketplace)

	elif Input.is_action_just_pressed("Chat"):
		WorldGUIManager.ChangeGui(Chat, false)

	elif Input.is_action_just_pressed("close_gui"):

		WorldGUIManager.CloseGui()

	# Grid toggling
	if Input.is_action_just_pressed("toggle_place") and PlayerState.current_state == PlayerState.STATE_TYPE.WORLD and (Data.ItemData[str(Global.InventoryNode.current_item)].TYPE == "BLOCK" or Data.ItemData[str(Global.InventoryNode.current_item)].TYPE == "BACKGROUND"):
		should_update_grid = not should_update_grid
	elif not (Data.ItemData[str(Global.InventoryNode.current_item)].TYPE == "BLOCK" or Data.ItemData[str(Global.InventoryNode.current_item)].TYPE == "BACKGROUND"):
		should_update_grid = false

	# Leave the world (CHANGE LATER TO PLANET MENU)

	if Input.is_action_just_pressed("zoom_in") and PlayerState.current_state == PlayerState.STATE_TYPE.WORLD:
		currentCameraZoom = clamp(currentCameraZoom + 1, cameraZoomRange.x, cameraZoomRange.y)
	if Input.is_action_just_pressed("zoom_out") and PlayerState.current_state == PlayerState.STATE_TYPE.WORLD:
		currentCameraZoom = clamp(currentCameraZoom - 1, cameraZoomRange.x, cameraZoomRange.y)
	if Input.is_action_just_pressed("Pause"):
		WorldGUIManager.ChangeGui(Pause)

func ShowRewards(item_array: Array, _can_buy_again: bool) -> void:
	WorldGUIManager.ChangeGui(Rewards)
	Rewards.ShowRewards(item_array)
	Rewards.BuyAgainButton.disabled = not _can_buy_again


func ClampCamera() -> void:
	if Global.WorldData:
		$Camera.limit_left = 0
		$Camera.limit_top = 0
		$Camera.limit_right = Global.WorldData.WorldSize.x * 32
		$Camera.limit_bottom = Global.WorldData.WorldSize.y * 32


func SendPosition() -> void:
	while true:
		var current_animation = $Player/AnimationPlayer.current_animation
		var animation_state = $Player.animation_to_enum(current_animation)
		Server.UpdatePositionRequest($Player.position, animation_state, $Player/Sprite.flip_h, $Player.velocity)
		await get_tree().create_timer(0.075).timeout


func UpdateHealthBar() -> void:
	$HUD/BitsAndHealth/HealthBarSprite.frame = floor(Player.health / 25)


func PromptInventory() -> int:
	WorldGUIManager.ChangeGui(Inventory)
	Inventory.update_bits()
	Inventory.prompting = true
	await Inventory.prompt_finished
	return Inventory.current_item


func PromptItemAdder() -> int:
	if WorldGUIManager.gui_stack.front() != ItemAdder:
		WorldGUIManager.ChangeGui(ItemAdder)
	await ItemAdder.prompt_finished
	return ItemAdder.amount



func DroppedItemUpdate(dropped_data, world_loading: bool = false) -> void:
	for dropped_item in Dropped.get_children():
		if dropped_item.drop_UID == dropped_data[2]: # if dropped item already exists, then we're updating the amount

			dropped_item.item_amount = dropped_data[1]
			dropped_item.updateDroppedItem()
			print("dropped item amount updated")
			return

	var new_dropped_item = DroppedItem.instantiate()

	new_dropped_item.item_id = dropped_data[0]
	new_dropped_item.item_amount = dropped_data[1]
	new_dropped_item.drop_UID = dropped_data[2]

	Dropped.add_child(new_dropped_item)
	new_dropped_item.LoadItem()
	
	if not world_loading:
		new_dropped_item.get_node("DropSound").play()

func _on_shop_button_pressed() -> void:
	WorldGUIManager.ChangeGui(Shop)



func _on_pause_menu_button_pressed():
	WorldGUIManager.ChangeGui(Pause)


func _on_marketplace_button_pressed():
	WorldGUIManager.ChangeGui(Marketplace)


func _on_inventory_button_pressed():
	WorldGUIManager.ChangeGui(Inventory)
	Inventory.update_bits()


func _on_chat_button_pressed():
	WorldGUIManager.ChangeGui(Chat, false)
	Global.ChatNode.get_node("ChatInput").grab_focus()

func setDoorCollisions():
	for door in DoorCollision:
		if door.closed:
			pass
