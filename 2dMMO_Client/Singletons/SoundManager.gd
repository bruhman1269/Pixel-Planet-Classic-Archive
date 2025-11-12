extends Node

var num_players = 25
var available = []
var bus = "Game"

var previous_scene: Node = null

@onready var sound: AudioStreamPlayer = AudioStreamPlayer.new()

@onready var click_path = load("res://Assets/Audio/ButtonClick.ogg")
@onready var hover_path = load("res://Assets/Audio/ButtonHover.ogg")
@onready var type_path = load("res://Assets/Audio/Keystrike.ogg")

func _ready() -> void:
	# check when scene changes
	get_tree().connect("tree_changed", _on_tree_changed)
	
	# Create the pool of AudioStreamPlayer nodes.
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.connect("finished", _on_stream_finished.bind([p]))
		p.bus = bus

func _on_tree_changed():
	var current_scene
	
	if get_tree() != null and get_tree().get_current_scene() != null:
		current_scene = get_tree().get_current_scene()
	
	if current_scene == previous_scene:
		return  # Ignore if the scene hasn't changed
	
	previous_scene = current_scene
	
	await get_tree().process_frame
	
	var buttons: Array
	var lineedits: Array
	
	if current_scene != null:
		buttons = get_node_in_scene(current_scene, "Button")
		lineedits = get_node_in_scene(current_scene, "LineEdit")
	
	if buttons != null:
		for inst in buttons:
			inst.connect("pressed", on_button_pressed.bind([inst][0]))
			inst.connect("mouse_entered", on_focus_entered.bind([inst][0]))
			inst.connect("text_changed", on_text_changed.bind([inst][0]))
	
	if lineedits != null:
		for inst in lineedits:
			inst.connect("text_changed", on_text_changed.bind([inst][0]))

func get_node_in_scene(scene: Node, type_to_find: String) -> Array:
	var interactive: Array = []
	
	if scene != null:
		var children = scene.get_children()

		for child in children:
			
			if child.is_in_group("Ignore"):
				continue
			
			if child.get_class() == type_to_find:
				interactive.append(child)
				
			if child.get_child_count() > 0:
				var child_interactive = get_node_in_scene(child, type_to_find)
				interactive += child_interactive

	return interactive

func on_button_pressed(inst) -> void:
	if inst.disabled:
		return
	
	if len(available) != 0:
		available[0].stream = click_path
		available[0].set_volume_db(-5) # This is where we set the volume from the settings
		available[0].set_pitch_scale(randf_range(1.0, 3.5))
		available[0].play()
		available.pop_front()

func on_focus_entered(inst) -> void:
	if inst.disabled:
		return
		
	if len(available) != 0:
		available[0].stream = hover_path
		available[0].set_volume_db(-5) # This is where we set the volume from the settings
		available[0].set_pitch_scale(randf_range(1.5, 3.0))
		available[0].play()
		available.pop_front()

func on_text_changed(new_text, inst):
	if not inst.editable:
		return
	
	if len(available) != 0:
		available[0].stream = type_path
		available[0].set_volume_db(-12) # This is where we set the volume from the settings
		available[0].set_pitch_scale(2.5)
		available[0].play()
		available.pop_front()

func _on_stream_finished(stream) -> void:
	stream = available[0]
	stream.bus = bus
	stream.set_volume_db(AudioServer.get_bus_volume_db(0))
	available.append(stream)

func _on_instance_scene(scene) -> void:
	# A new scene has been instanced
	# You can perform any necessary initialization here
	# For example, connecting signals or setting up initial states
	# Access the newly instanced scene via the 'scene' parameter
	var buttons: Array
	var lineedits: Array
	
	if scene != null:
		buttons = get_node_in_scene(scene, "Button")
		lineedits = get_node_in_scene(scene, "LineEdit")

	if buttons != null:
		for inst in buttons:
			inst.connect("pressed", on_button_pressed.bind([inst][0]))
			inst.connect("mouse_entered", on_focus_entered.bind([inst][0]))
			inst.connect("text_changed", on_text_changed.bind([inst][0]))
	
	if lineedits != null:
		for inst in lineedits:
			inst.connect("text_changed", on_text_changed.bind([inst][0]))

func _notification(what):
	var current_scene
	if what == NOTIFICATION_POSTINITIALIZE:
		
		current_scene = get_tree().get_current_scene()
		await get_tree().process_frame
		
		var buttons: Array
		var lineedits: Array
		
		if current_scene != null:
			buttons = get_node_in_scene(current_scene, "Button")
			lineedits = get_node_in_scene(current_scene, "LineEdit")
		
		if buttons != null:
			for inst in buttons:
				inst.connect("pressed", on_button_pressed.bind([inst][0]))
				inst.connect("mouse_entered", on_focus_entered.bind([inst][0]))
				inst.connect("text_changed", on_text_changed.bind([inst][0]))
		
		if lineedits != null:
			for inst in lineedits:
				inst.connect("text_changed", on_text_changed.bind([inst][0]))
