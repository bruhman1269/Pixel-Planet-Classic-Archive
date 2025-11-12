extends GUIBase

var page_number: int = 0
var last_search_data: Array = []

@onready var listing = preload("res://Scenes/GuiScenes/Marketplace/Listing.tscn").instantiate()
@onready var listings = $Listings
@onready var page_label: Label = $Panel2/PageLabel

static func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()

func SetListings(_search_results: Array) -> void:
	last_search_data = _search_results
	delete_children(listings)
	
	page_label.text = "Pg " + str(page_number)
	
	var index: int = 0
	for result in _search_results:
	
		var unit_price: int = ceil(result.price / result.item_amount)
		var timestamp: String = Time.get_time_string_from_unix_time(result.expiration - Time.get_unix_time_from_system())
		
		var new_listing: Panel = listing.duplicate()
		new_listing.listing_id = result.id
		new_listing.get_node("ItemSprite").frame = result.item_id + 1
		new_listing.get_node("ItemAmount").text = str(result.item_amount)
		new_listing.get_node("ExpirationLabel").text = "EXPIRES IN " + timestamp
		new_listing.get_node("TitleLabel").text = str(result.item_amount) + " " + Data.ItemData[str(result.item_id)].NAME + " | Est Unit: " + str(unit_price)
		new_listing.get_node("PurchaseButton").text = str(result.price) + " Bits"
		new_listing.expiration_time = result.expiration
		new_listing.position = Vector2(10, 21 + 44 * index)
		
		listings.add_child(new_listing)
		
		index += 1


func DisableListing(listing_id: int) -> void:
	for listing in listings.get_children():
		if listing.listing_id == listing_id:
			listing.purchase_button.disabled = true
			listing.expiration_label.text = "PURCHASED"


func update_listings() -> void:
	
	for list in listings.get_children():
		list.get_node("ExpirationLabel").text = "EXPIRES IN " + str(list.expiration_time)
		if list.expiration_time <= Time.get_unix_time_from_system():
			list.get_node("ExpirationLabel").text = "EXPIRED"
			list.get_node("PurchaseButton").disabled = true


func search(_page_number: int) -> void:
	Server.SearchMarketplaceRequest($BuySellPanel/Buy/ItemName.text, Global.WorldNode.ItemFilters.min_price, Global.WorldNode.ItemFilters.max_price, _page_number, false)


func OnOpen():
	search(0)
	$BuySellPanel/Buy/ItemName.text = Global.WorldNode.ItemFilters.item_name
	$BuySellPanel.current_tab = 0
	page_number = 0


func _on_filter_button_pressed() -> void:
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.ItemFilters)


func _on_buy_sell_panel_tab_changed(tab: int) -> void:
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.SellItem)


func _on_search_button_pressed() -> void:
	search(0)


func _on_refresh_button_pressed() -> void:
	search(page_number)


func _on_page_up_button_pressed() -> void:
	if len(last_search_data) == 7:
		page_number += 1
		search(page_number)


func _on_page_down_button_pressed() -> void:
	if page_number > 0:
		page_number -= 1
		search(page_number)
