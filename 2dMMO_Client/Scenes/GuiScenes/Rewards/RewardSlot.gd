extends Control

var ITEM_ID
var open: bool = false
var AMOUNT

#@onready var explodeRarityParticle = load("res://Particles/RarityExplode/RarityExplode.tscn")


@onready var item_data = {
	
}

@onready var parent = get_parent().get_parent()

func _ready():
	#item_data = ItemData.item_data[str(item_id)]
	#$Slot/ItemIcon.frame = item_id
	#$Slot/itemamount.text = str(amount)
	pass


func setup(item_id, amount):
	ITEM_ID = item_id
	AMOUNT = amount
	$ItemIcon.frame = item_id + 1
	$ItemAmount.text = str(amount)

func FetchItemData(item_id):
	return Data.ItemData[str(item_id)]


func Reveal():
	
	if not open:
		open = true
		$ItemCover.visible = false
		$SFX.play()
		#var particle = explodeRarityParticle.instantiate()
		#
		#self.add_child(particle)
	
	parent.updateButtons()


func _on_reward_pressed() -> void:
	print("clicked on slot")
	
	#if FetchItemData(ITEM_ID).ITEM_RARITY == "Legendary":%
		#pass
	
	Reveal()
