extends Node

var DB: SQLite

var marketplace_remove_buffers: Dictionary = {}

# Account constants
const _PASSWORD_HASH_AMOUNT: int = 50000
const _ADDRESS_HASH_AMOUNT: int = 10
const _MIN_USERNAME_LENGTH: int = 3
const _MAX_USERNAME_LENGTH: int = 32
const _MIN_PASSWORD_LENGTH: int = 3
const _MAX_PASSWORD_LENGTH: int = 256
const _MAX_ACCOUNTS_PER_IP: int = 10

# Marketplace constants
const _MARKETPLACE_PAGE_LENGTH: int = 7


enum RegisterCodes {
	NAME_LENGTH_ERROR,
	INTERNAL_DATABASE_ERROR,
	SUCCESS,
	ERROR,
	TOO_MANY_ACCOUNTS
}

func _ready():
	if not FileAccess.file_exists(Global.DATABASE_PATH):
		DirAccess.copy_absolute("res://Data/db.db", Global.DATABASE_PATH)
	
	
	# Open database
	DB = SQLite.new()
	DB.path = Global.DATABASE_PATH
	print("DB Path: ", DB.path)
	DB.verbosity_level = SQLite.QUIET
	
	DB.open_db()


func Close() -> void:
	DB.close_db()


# Registers user to database
func RegisterUser(_username: String, _password: String, _address: String) -> String:

	if _username.length() > _MAX_USERNAME_LENGTH or _username.length() < _MIN_USERNAME_LENGTH:
		return "Username must be between " + str(_MIN_USERNAME_LENGTH) + " and " + str(_MAX_USERNAME_LENGTH) + " characters long!"
	elif _password.length() > _MAX_PASSWORD_LENGTH or _password.length() < _MIN_PASSWORD_LENGTH:
		return "Password must be between " + str(_MIN_PASSWORD_LENGTH) + " and " + str(_MAX_PASSWORD_LENGTH) + " characters long!"

	if not DB:
		print("database not found")
		return "Internal database error!"
	
	print("database found")
	
	# Create a query to check if the username already exists
	var CheckUsernameQueryString: String = "SELECT * FROM accounts WHERE username = ?;"
	var CheckUsernameParamBindings: Array = [_username]
	var CheckUsernameSuccess: bool = DB.query_with_bindings(CheckUsernameQueryString, CheckUsernameParamBindings)
	var CheckUsernameResult: Array = DB.query_result
	
	# Hash address
	for n in _ADDRESS_HASH_AMOUNT:
		_address = _address.sha256_text()

	print("address hashed")

	# Create a query to check if user's ip already has the max amount of accounts made
	var CheckAddressQueryString: String = "SELECT * FROM accounts WHERE address = ?"
	var CheckAddressParamBindings: Array = [_address]
	var CheckAddressSuccess: bool = DB.query_with_bindings(CheckAddressQueryString, CheckAddressParamBindings)
	var CheckAddressResult: Array = DB.query_result


	# If the query was a success, and the username doesn't already exist, then an account can be created
	if CheckUsernameSuccess and CheckAddressSuccess and CheckAddressResult.size() < _MAX_ACCOUNTS_PER_IP and CheckUsernameResult.size() == 0:
		
		# Create hashed password
		for n in _PASSWORD_HASH_AMOUNT:
			_password = _password.sha256_text()
		
		var AccountCreationSuccess: bool = DB.insert_row("accounts", {
			username = _username,
			password = _password,
			address = _address
		})
		
		if AccountCreationSuccess:
			return "Success creating account!"
		else:
			return "Error when creating account. Please try again."
		
	elif not CheckUsernameSuccess or not CheckAddressSuccess:

		return "Error when creating account. Please try again."
	elif CheckUsernameResult.size() > 0:

		return "Account with username " + _username + " already exists!"
	elif CheckAddressResult.size() >= _MAX_ACCOUNTS_PER_IP:
		
		return "Too many accounts created on this computer!"
	
	return "Error when creating account. Please try again."


func replacePassword(_username: String, _password: String):
	
	for n in _PASSWORD_HASH_AMOUNT:
		_password = _password.sha256_text()
	
	var InventoryQueryString: String = "UPDATE accounts SET password=? WHERE username = ?;"
	var InventoryParamBindings: Array = [_password, _username]
	var InventorySuccess: bool = DB.query_with_bindings(InventoryQueryString, InventoryParamBindings)
	var Result: Array = DB.query_result
	
	if InventorySuccess and Result.size() > 0:
		return true
	return false

func doesAccountExist(username):
	var CheckPeerQueryString := "SELECT * FROM accounts WHERE username = ?"
	var CheckPeerQueryBindings: Array = [username]
	var CheckPeerQuerySuccess: bool = DB.query_with_bindings(CheckPeerQueryString, CheckPeerQueryBindings)
	var CheckPeerQueryResult: Array = DB.query_result
	
	if len(CheckPeerQueryResult) == 0:
		return false
	return true

# Authenticates user
func AuthenticateUser(_username: String, _password: String) -> Array:
	
	if not DB:
		print("database not found")
		return [false, ""]
	# Create hashed password
	for n in _PASSWORD_HASH_AMOUNT:
		_password = _password.sha256_text()
	
	var CheckUsernameQueryString: String = "SELECT * FROM accounts WHERE username = ? AND password = ?;"
	var CheckUsernameParamBindings: Array = [_username, _password]
	var CheckUsernameSuccess: bool = DB.query_with_bindings(CheckUsernameQueryString, CheckUsernameParamBindings)
	var Result: Array = DB.query_result
	
	if CheckUsernameSuccess and Result.size() > 0:
		return [true, Result[0]]
	else:
		print("no users found")
		return [false, ""]


# Retrieves world id
func RetrieveWorldId(_world_name: String) -> int:
	
	var WorldIdQueryString: String = "SELECT * FROM worlds WHERE name = ?"
	var WorldIdParamBindings: Array = [_world_name]
	var WorldIdSuccess: bool = DB.query_with_bindings(WorldIdQueryString, WorldIdParamBindings)
	var WorldIdResult: Array = DB.query_result

	if WorldIdSuccess and WorldIdResult.size() > 0:
		print(WorldIdResult)
		return WorldIdResult[0].id
		
	else:

		var WorldIdCreationSuccess: bool = DB.insert_row("worlds", {
			name = _world_name
		})

		if WorldIdCreationSuccess:
			
			WorldIdQueryString = "SELECT * FROM worlds WHERE name = ?"
			WorldIdParamBindings = [_world_name]
			WorldIdSuccess = DB.query_with_bindings(WorldIdQueryString, WorldIdParamBindings)
			WorldIdResult = DB.query_result
			
			if WorldIdSuccess and WorldIdResult.size() > 0:
				print(WorldIdResult)
				return WorldIdResult[0].id
	
	return -1


func SaveInventory(_username: String, _inventory: Array, _bits: int, _clothes: Dictionary, permission_level: int) -> void:

	if not DB:
		return

	var InventoryQueryString: String = "UPDATE accounts SET inventory=?, bits=?, clothes=?, permission_level=? WHERE username = ?;"
	var InventoryParamBindings: Array = [var_to_str(_inventory), _bits, var_to_str(_clothes), permission_level, _username]
	var InventorySuccess: bool = DB.query_with_bindings(InventoryQueryString, InventoryParamBindings)
	var Result: Array = DB.query_result

	if InventorySuccess and Result.size() > 0:
		return

func SaveAccountInfo(_username: String, _email: String) -> void:

	if not DB:
		return

	var InventoryQueryString: String = "UPDATE accounts SET email=? WHERE username = ?;"
	var InventoryParamBindings: Array = [_email, _username]
	var InventorySuccess: bool = DB.query_with_bindings(InventoryQueryString, InventoryParamBindings)
	var Result: Array = DB.query_result

	if InventorySuccess and Result.size() > 0:
		return

func CreateMarketplaceListing(_item_id: int, _item_amount: int, _price: int, _hours_active: int, _seller_id: int) -> bool:
	var item_data = Data.ItemData[str(_item_id)]
	
	if item_data.has("UNSELLABLE") and item_data.UNSELLABLE == true: return false
	
	var item_name: String = item_data.NAME
	
	# Check if user has available slots
	var ListingQueryString: String = "SELECT * FROM marketplace WHERE seller_id = ?"
	var ListingQueryParamBindings: Array = [_seller_id]
	var ListingQuerySuccess: bool = DB.query_with_bindings(ListingQueryString, ListingQueryParamBindings)
	var ListingQueryResult: Array = DB.query_result
	
	if not ListingQuerySuccess or ListingQueryResult.size() >= 6: return false
	
	# Put listing into database
	DB.insert_row("marketplace", {
		expiration = int(Time.get_unix_time_from_system()) + _hours_active * 3600,
		item_id = _item_id,
		item_amount = _item_amount,
		price = _price,
		item_name = item_name.to_upper(),
		seller_id = _seller_id,
		sold = 0
	})
	
	return true


func SearchMarketplaceListings(_item_name: String, _min_price: int, _max_price: int, _page_number: int, _seller_id: int, is_seller: bool) -> Dictionary:
	
	var SearchResult: Dictionary = {
		SUCCESS = false,
		LISTINGS = []
	}
	
	var SearchQueryString: String
	var SearchQueryParamBindings: Array
	
	var time: int = int(Time.get_unix_time_from_system())
	
	# If the item name is empty, perform a search without it as an arg
	if is_seller == true:
		SearchQueryString = "SELECT * FROM marketplace WHERE price >= ? AND price <= ? AND seller_id == ? LIMIT ? OFFSET ?"
		SearchQueryParamBindings = [_min_price, _max_price, _seller_id, _MARKETPLACE_PAGE_LENGTH, _page_number * _MARKETPLACE_PAGE_LENGTH]
	elif _item_name == "":
		SearchQueryString = "SELECT * FROM marketplace WHERE price >= ? AND price <= ? AND expiration > ? AND seller_id != ? AND sold == 0  LIMIT ? OFFSET ?"
		SearchQueryParamBindings = [_min_price, _max_price, time, _seller_id, _MARKETPLACE_PAGE_LENGTH, _page_number * _MARKETPLACE_PAGE_LENGTH]
	else:
		SearchQueryString = "SELECT * FROM marketplace WHERE instr(item_name, ?) > 0 AND price >= ? AND price <= ? AND expiration > ? AND seller_id != ? AND sold == 0  LIMIT ? OFFSET ?"
		SearchQueryParamBindings = [_item_name.to_upper(), _min_price, _max_price, time, _seller_id, _MARKETPLACE_PAGE_LENGTH, _page_number * _MARKETPLACE_PAGE_LENGTH]
	
	var SearchQuerySuccess: bool = DB.query_with_bindings(SearchQueryString, SearchQueryParamBindings)
	var SearchQueryResult: Array = DB.query_result
	
	SearchResult.SUCCESS = SearchQuerySuccess
	SearchResult.LISTINGS = SearchQueryResult
	
	return SearchResult


func GetListingFromId(_listing_id: int) -> Dictionary:

	var SearchResult: Dictionary = {
		SUCCESS = false,
		LISTINGS = []
	}

	var SearchQueryString: String = "SELECT * FROM marketplace where id = ?"
	var SearchQueryParamBindings: Array = [_listing_id]
	var SearchQuerySuccess: bool = DB.query_with_bindings(SearchQueryString, SearchQueryParamBindings)
	var SearchQueryResult: Array = DB.query_result

	SearchResult.SUCCESS = SearchQueryResult.size() > 0
	SearchResult.LISTINGS = SearchQueryResult

	return SearchResult


func RemoveListingWithId(_listing_id: int) -> bool:
	
	if marketplace_remove_buffers.has(_listing_id): return false
	
	marketplace_remove_buffers[_listing_id] = true
	
	#var SearchQueryString: String = "SELECT * FROM marketplace where id = ?"
	#var SearchQueryParamBindings: Array = [_listing_id]
	#var SearchQuerySuccess: bool = DB.query_with_bindings(SearchQueryString, SearchQueryParamBindings)
	#
	#var is_peer: bool = false
	#if SearchQuerySuccess:
		#if DB.query_result[0].seller_id == peer_database_id:
			#is_peer = true
	#else:
		#return {success = false}
	
	var RemoveQueryString: String = "UPDATE marketplace SET sold = 1 WHERE id = ?"
	var RemoveQueryParamBindings: Array = [_listing_id]
	var RemoveQuerySuccess: bool = DB.query_with_bindings(RemoveQueryString, RemoveQueryParamBindings)

	marketplace_remove_buffers.erase(_listing_id)

	return RemoveQuerySuccess


func DeleteListingWithId(listing_id: int) -> void:
	var RemoveQueryString: String = "DELETE FROM marketplace WHERE id = ?"
	var RemoveQueryParamBindings: Array = [listing_id]
	DB.query_with_bindings(RemoveQueryString, RemoveQueryParamBindings)


func SetBanned(peer_name: String, banned: bool) -> void:
	var CheckPeerQueryString := "SELECT * FROM accounts WHERE username = ?"
	var CheckPeerQueryBindings: Array = [peer_name]
	var CheckPeerQuerySuccess: bool = DB.query_with_bindings(CheckPeerQueryString, CheckPeerQueryBindings)
	var CheckPeerQueryResult: Array = DB.query_result
	
	if len(CheckPeerQueryResult) == 0: return
	
	var should_ban: int = 0
	if banned == true:
		should_ban = 1
	
	var SetBannedQueryString := "UPDATE accounts SET banned = ? WHERE id = ?"
	var SetBannedQueryBindings: Array = [should_ban, CheckPeerQueryResult[0].id]
	DB.query_with_bindings(SetBannedQueryString, SetBannedQueryBindings)

func SetBannedOffline(peer_name: String):
	var CheckPeerQueryString := "SELECT * FROM accounts WHERE username = ?"
	var CheckPeerQueryBindings: Array = [peer_name]
	var CheckPeerQuerySuccess: bool = DB.query_with_bindings(CheckPeerQueryString, CheckPeerQueryBindings)
	var CheckPeerQueryResult: Array = DB.query_result
	
	if len(CheckPeerQueryResult) == 0:
		return "Account " + peer_name + " does not exist!"
	
	if CheckPeerQueryResult[0]["permission_level"] >= 4:
		return peer_name + " cannot be banned!"
	
	if CheckPeerQueryResult[0]["banned"] == 1:
		return peer_name + " is already banned!"
	else:
		SetBanned(peer_name, true)
		return "You have banned " + peer_name + " indefinitely"

func SetMuted(peer_name: String, muted: bool) -> void:
	var CheckPeerQueryString := "SELECT * FROM accounts WHERE username = ?"
	var CheckPeerQueryBindings: Array = [peer_name]
	var CheckPeerQuerySuccess: bool = DB.query_with_bindings(CheckPeerQueryString, CheckPeerQueryBindings)
	var CheckPeerQueryResult: Array = DB.query_result
	
	if len(CheckPeerQueryResult) == 0: return
	
	var should_mute: int = 0
	if muted == true:
		should_mute = 1
	
	var SetBannedQueryString := "UPDATE accounts SET muted = ? WHERE id = ?"
	var SetBannedQueryBindings: Array = [should_mute, CheckPeerQueryResult[0].id]
	DB.query_with_bindings(SetBannedQueryString, SetBannedQueryBindings)
