extends Panel

var pack_id = ""
var price: int = 0
func _on_purchase_pressed() -> void:
	Server.ShopPurchaseRequest(pack_id)
	Global.WorldNode.Rewards.current_pack_id = self.pack_id
