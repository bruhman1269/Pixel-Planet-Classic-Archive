extends GUIBase

var panels: Dictionary = {}

var xscrolloffset = 0

func _ready():
	load_packs()

func _input(event):
	pass
	#if event is InputEventMouseButton:
		#print(xscrolloffset)
		#if self.visible:
			#if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				#xscrolloffset = clamp(xscrolloffset + 15, 0, 1600)
				#
				#for panel in $ShopPanel/Container.get_children():
					#var cur_panel_pos = panels[panel]
					#panel.position.x = cur_panel_pos.x - xscrolloffset
				#
			#elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				#xscrolloffset = clamp(xscrolloffset - 15, 0, 1600)
				#
				#for panel in $ShopPanel/Container.get_children():
					#var cur_panel_pos = panels[panel]
					#panel.position.x = cur_panel_pos.x - xscrolloffset


func OnOpen():
	for panel in $ShopPanel/Scroll/Container.get_children():
		panel.get_node("Purchase").disabled = panel.price > Global.SelfData.Bits
	#xscrolloffset = 0


func items_packed(items_unpacked):
	var reward_scene = load("res://Scenes/UI/Rewards/Rewards.tscn").instance()
	reward_scene.ShowRewards(items_unpacked)
	get_parent().add_child(reward_scene)
	
func load_packs():
	var index = 0
	for pack in Data.ShopData:
		var pack_info = Data.ShopData[pack]
		var new_shop_panel = preload("res://Scenes/GuiScenes/Shop/ShopPanel.tscn").instantiate()
		
		new_shop_panel.pack_id = pack
		new_shop_panel.price = pack_info.PRICE
		new_shop_panel.get_node("Icon").frame = pack_info.FRAME
		new_shop_panel.get_node("Info").text = pack_info.NAME + "\n" + pack_info.DESCRIPTION
		new_shop_panel.get_node("Purchase").text = format_score(str(pack_info.PRICE))
		
		$ShopPanel/Scroll/Container.add_child(new_shop_panel)


func format_score(score : String) -> String: # shoutout to the guy on godot forums who posted this
	var i : int = score.length() - 3
	while i > 0:
		score = score.insert(i, ",")
		i -= 3
	return score


func _on_close_pressed() -> void:
	Global.WorldNode.WorldGUIManager.CloseGui()
