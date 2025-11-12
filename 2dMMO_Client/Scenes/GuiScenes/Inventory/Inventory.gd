extends GUIBase

@onready var InventorySlot = preload("res://Scenes/GuiScenes/Inventory/InventorySlot.tscn")

var current_item: int = 0
var current_item_amount: int = 1

var prompting: bool = false

@onready var drag_animation = $DragItemIcon/AnimationPlayer
var dragging: bool = false
var dragging_id: int = -1
var old_mouse_position = Vector2.ZERO
var old_sprite_position = Vector2.ZERO

var in_drop_zone: bool = false

signal prompt_finished

var last_selected_inventory_slot = null


func OnOpen():
	dragging = false


func _ready() -> void:
	Global.InventoryNode = self
	$PlayerView/Player.get_node("AnimationPlayer").play("idle")
	$PlayerView/username.text = Global.Username

func SetSlots() -> void:
	for item in Global.SelfData.Inventory:
		var NewSlot = InventorySlot.instantiate()
		if item[0] != -1:
			NewSlot.get_node("ItemPicture").frame = item[0] + 1
			NewSlot.item_id = item[0]
			NewSlot.amount = item[1]
			NewSlot.item_data = Data.ItemData[str(item[0])]
			
			if item[1] > 1:
				NewSlot.get_node("AmountLabel").text = str(item[1])
				NewSlot.get_node("AmountLabelBackground").text = str(item[1])
		$Panel/GridContainer.add_child(NewSlot)


func UpdateSlot(_slot_data: Array) -> void:
	for slot in $Panel/GridContainer.get_children():
		if slot.item_id == int(_slot_data[0]):
			slot.amount += int(_slot_data[1])
			slot.Update()
			return
		
		elif slot.item_id == -1:
			slot.item_id = int(_slot_data[0])
			slot.amount += int(_slot_data[1])
			slot.Update()
			return

func update_bits():
	$Bits/bits.text = Global.comma_sep(Global.SelfData.Bits)

func _process(delta):
	
	if visible:
		update_player_view()
	
	if dragging and not prompting:
		
		$DragItemIcon.visible = true
		$DragItemIcon.frame = dragging_id + 1
		
		$DragItemIcon.global_position = lerp($DragItemIcon.global_position, get_global_mouse_position(), 0.4)
		
		var direction_vector = rad_to_deg(old_sprite_position.angle_to(get_global_mouse_position()))
		
		var target_rotation = -direction_vector * 12.0
		$DragItemIcon.rotation_degrees = lerp($DragItemIcon.rotation_degrees, target_rotation, 0.4)
		
		$DragItemIcon.rotation_degrees = clamp($DragItemIcon.rotation_degrees, -30.0, 30.0) # clamp the maximum degrees icon rotates
		
		old_mouse_position = get_global_mouse_position()
		old_sprite_position = $DragItemIcon.global_position
		
	else:
		
		old_sprite_position = Vector2.ZERO
		$DragItemIcon.visible = false
		$DragItemIcon.global_position = get_global_mouse_position()
		$DragItemIcon.rotation_degrees = 0
	
func AddSlot() -> void:
	var NewSlot = InventorySlot.instantiate()
	$Panel/GridContainer.add_child(NewSlot)


func SetClothesSlots(_clothes: Dictionary) -> void:
	for slot in $Panel/GridContainer.get_children():
		
		for clothing_id in _clothes.values():
			if slot.item_id == clothing_id and clothing_id != -1:
				slot.Checkmark(true)
				break
			slot.Checkmark(false)

func DropAreaVisible(boolean):
	$DropLabel.visible = boolean

func isAreaVisible() -> bool:
	return $DropLabel.visible

func _on_area_2d_mouse_entered():
	
	in_drop_zone = true
	
	if dragging and not prompting:
		print("a")
		$DropAreaPlayer.play("Fade")
		drag_animation.play("Out")

func update_player_view():
	$PlayerView/Player.SetClothing(Global.SelfData.Clothes, true)


func _on_area_2d_mouse_exited():
	
	in_drop_zone = false
	
	if dragging and not prompting:
		$DropAreaPlayer.play_backwards("Fade")
		drag_animation.play_backwards("Out")
