extends Node

var ActiveWorlds: Dictionary = {}


func GetByName(_name: String, _peer: PeerData) -> WorldData:

	# If the world is currently active, return that
	if ActiveWorlds.has(_name):
		return ActiveWorlds[_name]

	# If the world is not currently active, load it and return it
	else:
		var NewWorld: WorldData = WorldData.new()
		NewWorld.Load(_name, _peer)
		ActiveWorlds[_name] = NewWorld
		
		return NewWorld


func CloseWorld(_name: String) -> void:
	if _name != "" and ActiveWorlds.has(_name):
		ActiveWorlds[_name].Save()
		ActiveWorlds.erase(_name)
