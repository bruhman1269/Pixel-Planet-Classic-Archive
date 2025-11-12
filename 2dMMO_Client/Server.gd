extends Node

const PORT: int = 27015


const ADDRESS: String = "127.0.0.1"

var Peer := ENetMultiplayerPeer.new()

var self_peer_id
var disconnected = false
var summon_position = Vector2(-2000, -2000)

#var AntiModify: Dictionary = {
	#"EngineRan": OS.has_feature("editor"),
	#"ApplicationCheckSum": "",
#}

func _ready() -> void:
	
	Connect()
	
	multiplayer.connect("connected_to_server", _connected_to_server)
	multiplayer.connect("connection_failed", on_connection_failed)
	multiplayer.connect("server_disconnected", on_server_disconnected)
	
	#Global.hash_app()
	#print(AntiModify)

func _connected_to_server() -> void:
	disconnected = true
	versionRequest()

func on_connection_failed():
	print("connection failed")

func on_server_disconnected():
	disconnected = true

	Disconnected.showDisconnect()
	print("server disconnected")


@rpc
func sendEvent():
	pass

@rpc
func returnEvent(event, parameters):
	Events.eventHandler(event, parameters)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Peer.close()


func Connect() -> void:

	Peer.create_client(ADDRESS, PORT)

	multiplayer.multiplayer_peer = Peer

	self_peer_id = multiplayer.get_unique_id()


func versionRequest() -> void:
	rpc_id(1, "sendEvent", "versionCheck", [Global.VERSION])

func registerRequest(_username: String, _password: String) -> void:
	rpc_id(1, "sendEvent", "registerRequest", [_username, _password])

func loginRequest(_username: String, _password: String) -> void:
	rpc_id(1, "sendEvent", "loginRequest", [_username, _password])

func worldJoinRequest(_world_name: String) -> void:
	rpc_id(1, "sendEvent", "worldJoinRequest", [_world_name])

func worldLeaveRequest() -> void:
	rpc_id(1, "sendEvent", "worldLeaveRequest", [])

func placeBlockRequest(_block_id: int, _coordinates: Vector2i, metadata: Dictionary) -> void:
	rpc_id(1, "sendEvent", "placeBlockRequest", [_block_id, _coordinates, metadata])

func BreakBlockRequest(_position: Vector2i) -> void:
	rpc_id(1, "sendEvent", "breakBlockRequest", [_position])

func UpdatePositionRequest(_position: Vector2, _current_state, _direction, _velocity) -> void:
	rpc_id(1, "sendEvent", "updatePositionRequest", [_position, _current_state, _direction, _velocity])


func EquipClothingRequest(_item_id: int) -> void:
	rpc_id(1, "sendEvent", "equipClothingRequest", [_item_id])


func ShopPurchaseRequest(_pack_id: String) -> void:
	rpc_id(1, "sendEvent", "shopPurchaseRequest", [_pack_id])


func CraftRequest(_item1_id: int, _item2_id: int, _item1_amount: int, _item2_amount: int) -> void:
	rpc_id(1, "sendEvent", "craftRequest", [_item1_id, _item2_id, _item1_amount, _item2_amount])


func GrindRequest(_item_id: int, _item_amount: int) -> void:
	rpc_id(1, "sendEvent", "grindRequest", [_item_id, _item_amount])


func ListItemRequest(_item_id: int, _item_amount: int, _price: int, _hours_active: int) -> void:
	rpc_id(1, "sendEvent", "listItemRequest", [_item_id, _item_amount, _price, _hours_active])


func SearchMarketplaceRequest(_item_name: String, _min_price: int, _max_price: int, _page_number: int, is_seller: bool) -> void:
	rpc_id(1, "sendEvent", "searchMarketplaceRequest", [_item_name, _min_price, _max_price, _page_number, is_seller])


func BuyListingRequest(_id: int) -> void:
	rpc_id(1, "sendEvent", "buyListingRequest", [_id])


func SetBlockMetadataRequest(position: Vector2i, metadata_info: Dictionary) -> void:
	rpc_id(1, "sendEvent", "setBlockMetadataRequest", [position, metadata_info])


func WorldClaimRequest() -> void:
	rpc_id(1, "sendEvent", "worldClaimRequest", [])

func ItemDropRequest(_item_id, _amount) -> void:
	rpc_id(1, "sendEvent", "itemDropRequest", [_item_id, _amount])
	print("player sent drop request")

func ItemDropPickupRequest(_drop_uid) -> void:
	rpc_id(1, "sendEvent", "itemDropPickupRequest", [_drop_uid])
