extends Control


enum ItemType {
	BITS,
	BLOCK,
	BACKGROUND,
	CLOTHING,
	INGREDIENT,
	FIST
}


enum ItemTag {
	UNSELLABLE,
	DOOR,
	SIGN,
	LIGHT,
	HURT,
	FLIGHT,
	PLATFORM,
	CRAFTING,
	DECORATION,
	FAST_BREAK,
	ENTRANCE,
	DISPLAY,
	BOUNCER,
	GRINDING
}


enum ItemTagDictKey {
	DROPS,
	CAN_COLLIDE,
	AUTOTILE,
	PLACE,
	HARDNESS,
	FLIGHT_TIME,
	PATH,
	BREAK_SPEED_MULT,
	BREAK_VFX,
	PET
}


enum BlockAutoTileMode {
	NONE,
	TWO,
	FOUR,
	SIXTEEN
}


enum ClothingType {
	BACK,
	PANTS,
	SHOES,
	SHIRT,
	HAIR,
	FACE,
	HAT,
	HAND
}


class ItemData:
	var _new: bool = true
	var ID: int = -2
	var TYPE: ItemType = 0
	var NAME: String = ""
	var DESCRIPTION: String = ""
	var TAGS: Array = []
	var TAGS_DICT: Dictionary = {}
	
	static func from_dict(from: Dictionary) -> ItemData:
		var new_item_data := ItemData.new()
		
		new_item_data._new = false
		new_item_data.TYPE = from.TYPE
		new_item_data.NAME = from.NAME
		new_item_data.DESCRIPTION = from.DESCRIPTION
		new_item_data.TAGS = from.TAGS
		new_item_data.TAGS_DICT = from.TAGS_DICT
		
		return new_item_data
	
	func to_dict() -> Dictionary:
		return {
			"TYPE": TYPE,
			"NAME": NAME,
			"DESCRIPTION": DESCRIPTION,
			"TAGS": TAGS,
			"TAGS_DICT": TAGS_DICT
		}


@onready var open_file_dialog := $OpenFileDialog
@onready var sync_file_dialog := $SyncFileDialog
@onready var item_list := %ItemList
@onready var tags_container := %TagsContainer
@onready var item_type_menu_btn := %ItemTypeMenuBtn
@onready var item_name_edit := %ItemNameEdit
@onready var item_desc_edit := %ItemDescEdit
@onready var tags_dict_menu_btn := %TagsDictMenuBtn
@onready var tags_dict_container := %TagsDictContainer
@onready var item_id_edit := %ItemIdEdit


var current_file_path: String = ""
var current_json_data: Dictionary = {}
var current_item_data: ItemData = ItemData.new()
var item_tag_dict_defaults := {
	[ItemTagDictKey.DROPS]: "[{\"AMOUNT\": 0,\"CHANCE\": 0.0,\"ITEM_ID\": -1}]",
	[ItemTagDictKey.CAN_COLLIDE]: "false",
	[ItemTagDictKey.AUTOTILE]: "NONE | TWO | FOUR | SIXTEEN",
	[ItemTagDictKey.PLACE]: "BACK | PANTS | SHOES | SHIRT | HAIR | FACE | HAT | HAND",
	[ItemTagDictKey.HARDNESS]: "0",
	[ItemTagDictKey.FLIGHT_TIME]: "0",
	[ItemTagDictKey.PATH]: "",
	[ItemTagDictKey.BREAK_SPEED_MULT]: "0.0",
	[ItemTagDictKey.BREAK_VFX]: "",
	[ItemTagDictKey.PET]: ""
}
var item_type_dict_tag_defaults := {
	[ItemType.BITS]: [],
	[ItemType.BLOCK]: [ItemTagDictKey.DROPS, ItemTagDictKey.CAN_COLLIDE, ItemTagDictKey.AUTOTILE, ItemTagDictKey.HARDNESS, ItemTagDictKey.PATH],
	[ItemType.BACKGROUND]: [ItemTagDictKey.DROPS, ItemTagDictKey.CAN_COLLIDE, ItemTagDictKey.AUTOTILE, ItemTagDictKey.HARDNESS, ItemTagDictKey.PATH],
	[ItemType.CLOTHING]: [ItemTagDictKey.PLACE, ItemTagDictKey.PATH],
	[ItemType.INGREDIENT]: [],
	[ItemType.FIST]: [],
}


func _ready() -> void:
	for tag in ItemTag.keys():
		var check_btn := CheckButton.new()
		check_btn.set_meta("enum_id", ItemTag.get(tag))
		check_btn.text = tag
		check_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tags_container.add_child(check_btn)
	
	for type in ItemType.keys():
		item_type_menu_btn.get_popup().add_item(type, ItemType.get(type))
	item_type_menu_btn.get_popup().id_pressed.connect(
		func(id: int) -> void:
			current_item_data.TYPE = ItemType.values()[id]
			set_item_type_menu()
	)
	
	for tag in ItemTagDictKey:
		tags_dict_menu_btn.get_popup().add_item(tag, ItemTagDictKey.get(tag))
	tags_dict_menu_btn.get_popup().id_pressed.connect(
		func(id: int) -> void:
			var new_text_edit := TextEdit.new()
			new_text_edit.custom_minimum_size.y = 40
			new_text_edit.text = "%s:%s" % [ItemTagDictKey.keys()[id], item_tag_dict_defaults[[id]]]
			tags_dict_container.add_child(new_text_edit)
	)
	
	import_prompt()


func _on_import_json_btn_pressed() -> void:
	import_prompt()


func _on_open_file_dialog_file_selected(path: String) -> void:
	current_file_path = path
	
	var file := FileAccess.open(current_file_path,FileAccess.READ)

	current_json_data = JSON.parse_string(file.get_as_text())
	file.close()
	
	
	#convert_old()
	
	load_items()

func _on_sync_file_dialog_file_selected(path: String) -> void:
	DirAccess.copy_absolute(current_file_path, path)


func _on_item_list_item_selected(index: int) -> void:
	var id_str: String = item_list.get_item_text(index).split(":")[0]
	current_item_data = ItemData.from_dict(current_json_data[id_str])
	current_item_data.ID = int(id_str)
	load_item_to_editor()


func import_prompt() -> void:
	open_file_dialog.visible = true


func load_item_to_editor() -> void:
	set_item_type_menu()
	load_tags_dict_container()
	item_name_edit.text = current_item_data.NAME
	item_desc_edit.text = current_item_data.DESCRIPTION
	item_id_edit.text = str(current_item_data.ID)
	
	for check_btn in tags_container.get_children():
		check_btn.button_pressed = false
		for tag in current_item_data.TAGS:
			if check_btn.get_meta("enum_id") == tag:
				check_btn.button_pressed = true
				break


func load_tags_dict_container() -> void:
	for child in tags_dict_container.get_children():
		child.queue_free()
	
	for tag in current_item_data.TAGS_DICT:
		var value = current_item_data.TAGS_DICT[tag]
		
		var new_text_edit := TextEdit.new()
		
		var value_str: String = str(value)
		
		if int(tag) == ItemTagDictKey.AUTOTILE:
			value_str = BlockAutoTileMode.keys()[value]
		elif int(tag) == ItemTagDictKey.PLACE:
			value_str = ClothingType.keys()[value]
		
		new_text_edit.text = "%s:%s" % [ItemTagDictKey.keys()[int(tag)], value_str]
		new_text_edit.custom_minimum_size.y = 40
		
		#if int(tag) == ItemTagDictKey.DROPS:
			#new_text_edit.custom_minimum_size.y = 300
		
		tags_dict_container.add_child(new_text_edit)


func load_items() -> void:
	item_list.clear()
	for key in current_json_data:
		var item: Dictionary = current_json_data[key]
		
		var new_item_data := ItemData.from_dict(item)
		
		item_list.add_item(str(key) + ": " + new_item_data.NAME)


func set_item_type_menu() -> void:
	item_type_menu_btn.text = "Item Type: " + ItemType.keys()[current_item_data.TYPE]
	
	for child in tags_dict_container.get_children():
		child.queue_free()
	
	for tag_dict_key in item_type_dict_tag_defaults[[current_item_data.TYPE]]:
		var new_text_edit := TextEdit.new()
		new_text_edit.custom_minimum_size.y = 40
		new_text_edit.text = "%s:%s" % [ItemTagDictKey.keys()[tag_dict_key], item_tag_dict_defaults[[tag_dict_key]]]
		tags_dict_container.add_child(new_text_edit)


var valid_keys: Array[String] = ["NAME", "DESCRIPTION"]
var array_tag_keys: Array[String] = ["UNSELLABLE", "DOOR", "SIGN", "LIGHT", ]
func convert_old() -> void:
	var new_item_data := {}
	
	for item_key in current_json_data:
		var item: Dictionary = current_json_data[item_key]
		
		var new_item := {
			DESCRIPTION = "",
			TAGS = [],
			TAGS_DICT = {}
		}
		
		for key in item:
			var kvalue = item[key]
			
			if not key in valid_keys:
				if key == "TYPE":
					new_item.TYPE = ItemType.get(kvalue)
				elif key in array_tag_keys:
					var current_tag: ItemTag
					match key:
						"UNSELLABLE":
							current_tag = ItemTag.UNSELLABLE
						"DOOR":
							current_tag = ItemTag.DOOR
						"SIGN":
							current_tag = ItemTag.SIGN
						"LIGHT":
							new_item.TAGS_DICT.LIGHT = [255, 255, 255, 255]
						
					if current_tag != null:
						new_item.TAGS.append(current_tag)
				else:
					if key == "TILESET_ID":
						continue
					
					if key == "SPECIALTY":
						new_item.TAGS.append(ItemTag.get(kvalue))
						continue
					
					print(key)
					var tag_enum: ItemTagDictKey = ItemTagDictKey.get(key)
						#print(ItemTag.keys()[new_item.TAGS[len(new_item.TAGS) - 1]])
					if key == "AUTOTILE":
						new_item.TAGS_DICT[str(tag_enum)] = BlockAutoTileMode.get(kvalue)
					elif key == "PLACE":
						new_item.TAGS_DICT[str(tag_enum)] = ClothingType.get(kvalue)
					else:
						new_item.TAGS_DICT[str(tag_enum)] = kvalue
			else:
				new_item[key] = kvalue
		if len(new_item.TAGS) != 0:
			print(new_item.TAGS)
		new_item_data[item_key] = new_item
	
	var file := FileAccess.open(current_file_path + "new", FileAccess.WRITE)
	file.store_string(str(new_item_data).replace("<null>", "").replace("\\'", "'"))
	file.close()


func _on_save_item_btn_pressed() -> void:
	current_item_data.ID = int(item_id_edit.text)
	current_item_data.DESCRIPTION = item_desc_edit.text
	current_item_data.NAME = item_name_edit.text
	
	current_item_data.TAGS = []
	for check_btn in tags_container.get_children():
		if check_btn.button_pressed == true:
			current_item_data.TAGS.append(check_btn.get_meta("enum_id"))
	
	current_item_data.TAGS_DICT = {}
	for text_edit in tags_dict_container.get_children():
		var c_index: int = text_edit.text.find(":")
		var enum_str: String = text_edit.text.left(c_index)
		var value_str: String = text_edit.text.right(-(c_index + 1))
		
		var value_var = str_to_var(value_str)
		if value_var == null:
			value_var = value_str
		
		var tag_dict_enum: ItemTagDictKey = ItemTagDictKey.get(enum_str)
		
		if tag_dict_enum == ItemTagDictKey.PLACE:
			value_var = ClothingType.get(value_var)
		elif tag_dict_enum == ItemTagDictKey.AUTOTILE:
			value_var = BlockAutoTileMode.get(value_var)
			
		current_item_data.TAGS_DICT[str(ItemTagDictKey.get(enum_str))] = value_var
	
	current_json_data[str(current_item_data.ID)] = current_item_data.to_dict()


func _on_save_json_btn_pressed() -> void:
	var file := FileAccess.open(current_file_path, FileAccess.WRITE)
	file.store_string(str(current_json_data).replace("<null>", "").replace("\\'", "'"))
	file.close()
	load_items()


func _on_new_item_btn_pressed() -> void:
	current_item_data = ItemData.new()
	load_item_to_editor()
