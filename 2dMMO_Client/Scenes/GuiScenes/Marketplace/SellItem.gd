extends GUIBase

var item_id: int = -1
var item_amount: int = 0
var price: int = 0
var expiration_hours: int = 0
var opening_from_itemselecter = false

@onready var listing = preload("res://Scenes/GuiScenes/Marketplace/Listing.tscn").instantiate()
@onready var listings = $Listings

static func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()


func update_slot() -> void:
	$Panel/ItemSprite.frame = self.item_id + 1
	$Panel/ItemAmount.text = str(self.item_amount)
	$Panel/TotalPriceEdit.text = str(self.price)
	
	if self.item_amount != 0:
		$Panel/UnitPriceEdit.text = str(self.price / self.item_amount)
	else:
		$Panel/UnitPriceEdit.text = "0"
	
	if self.item_id <= 0 or self.item_amount <= 0:
		$Panel/ItemSprite.frame = 0
		$Panel/ItemAmount.text = ""
		$Panel/TotalPriceEdit.editable = false
		$Panel/UnitPriceEdit.editable = false
		$Panel/HoursActiveEdit.editable = false
	else:
		$Panel/TotalPriceEdit.editable = true
		$Panel/UnitPriceEdit.editable = true
		$Panel/HoursActiveEdit.editable = true


func update_price() -> void:
	if self.price > 999999999:
		self.price = 999999999
		$Panel/TotalPriceEdit.text = str(self.price)
		$Panel/UnitPriceEdit.text = str(self.price / self.item_amount)


func update_createbtn() -> void:
	var valid: bool = self.item_id > 0 and self.item_amount > 0 and self.price > 0 and self.price < 999999999 and self.expiration_hours > 0 and self.expiration_hours <= 96
	$Panel/CreateListingButton.disabled = not valid
	
	if valid:
		$Panel/ResultLabel.visible = true
		$Panel/CreateListingButton.disabled = false
		$Panel/ResultLabel.text = "You are selling " + str(item_amount) + " " + Data.ItemData[str(item_id)].NAME + " for " + str(self.price / self.item_amount) + " bits each, with a total price of " + str(self.price) + " bits; it will expire in " + str(self.expiration_hours) + " hours."
	else:
		$Panel/CreateListingButton.disabled = true
		$Panel/ResultLabel.visible = false


func OnOpen():
	if opening_from_itemselecter == false:
		item_id = -1
		item_amount = 0
		price = 0
		expiration_hours = 0
		update_slot()
	opening_from_itemselecter = false
	$Panel/ResultLabel.text = ""
	$Panel/CreateListingButton.disabled = true
	$Panel/ResultLabel.visible = false
	print("openieng")
	Server.SearchMarketplaceRequest("", 1, 999999999, 0, true)


func SetListings(_search_results: Array) -> void:
	
	delete_children(listings)
	
	var index: int = 0
	for result in _search_results:
		
		var unit_price: int = ceil(result.price / result.item_amount)
		var time_diff = result.expiration - Time.get_unix_time_from_system()
		var timestamp: String = Time.get_time_string_from_unix_time(time_diff)
		
		var new_listing: Panel = listing.duplicate()
		new_listing.listing_id = result.id
		new_listing.get_node("ItemSprite").frame = result.item_id + 1
		new_listing.get_node("ItemAmount").text = str(result.item_amount)
		if time_diff > 0 and result.sold == 0:
			new_listing.get_node("ExpirationLabel").text = "EXPIRES IN " + timestamp
		elif time_diff <= 0:
			new_listing.get_node("ExpirationLabel").text = "EXPIRED"
		elif result.sold == 1:
			new_listing.get_node("ExpirationLabel").text = "SOLD"
		
		new_listing.get_node("TitleLabel").text = str(result.item_amount) + " " + result.item_name + " | Est Unit: " + str(unit_price)
		if result.sold == 0:
			new_listing.get_node("PurchaseButton").text = "Cancel"
		else:
			new_listing.get_node("PurchaseButton").text = "Claim"
		new_listing.expiration_time = result.expiration
		new_listing.position = Vector2(10, 21 + 44 * index)
		
		listings.add_child(new_listing)
		
		index += 1


func DisableListing(listing_id: int) -> void:
	for listing in listings.get_children():
		if listing.listing_id == listing_id:
			listing.purchase_button.disabled = true
			listing.expiration_label.text = "CLAIMED"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_item_button_pressed() -> void:
	Global.WorldNode.prompting_gui = self
	var item_id: int = await Global.WorldNode.PromptInventory()
	self.item_id = item_id
	opening_from_itemselecter = true
	
	var amount: int = await Global.WorldNode.PromptItemAdder()
	self.item_amount = amount
	
	if amount == 0:
		self.item_id = -1
		self.item_amount = 0
	
	Global.WorldNode.WorldGUIManager.ChangeGui(self)
	self.update_slot()
	self.update_createbtn()


func _on_total_price_edit_text_changed(new_text: String) -> void:
	self.price = int($Panel/TotalPriceEdit.text)
	if self.item_amount > 0:
		$Panel/UnitPriceEdit.text = str(self.price / self.item_amount)
	
	self.update_price()
	self.update_createbtn()


func _on_unit_price_edit_text_changed(new_text: String) -> void:
	self.price = self.item_amount * int($Panel/UnitPriceEdit.text)
	$Panel/TotalPriceEdit.text = str(self.price)
	self.update_price()
	self.update_createbtn()


func _on_cancel_button_pressed() -> void:
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Marketplace)


func _on_create_listing_button_pressed() -> void:
	
	Server.ListItemRequest(self.item_id, self.item_amount, self.price, self.expiration_hours)
	
	Global.WorldNode.WorldGUIManager.ChangeGui(Global.WorldNode.Marketplace)


func _on_hours_active_edit_text_changed(new_text: String) -> void:
	self.expiration_hours = int($Panel/HoursActiveEdit.text)
	self.update_createbtn()
