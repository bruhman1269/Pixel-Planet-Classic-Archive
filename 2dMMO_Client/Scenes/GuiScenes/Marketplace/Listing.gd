extends Panel

@onready var item_sprite = $ItemSprite
@onready var item_amount = $ItemAmount
@onready var expiration_label = $ExpirationLabel
@onready var title_label = $TitleLabel
@onready var purchase_button = $PurchaseButton

var expiration_time: int = 0
var listing_id: int = -1

func _ready() -> void:
	pass


func _on_purchase_button_pressed() -> void:
	if listing_id != -1:
		Server.BuyListingRequest(listing_id)
