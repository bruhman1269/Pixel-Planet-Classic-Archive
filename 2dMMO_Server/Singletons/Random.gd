extends Node


func WeightedRandom(_drops_array: Array) -> Array:
	var total: float = 0
	for drop in _drops_array:
		total += drop.CHANCE
	
	var rand = randf_range(0, total)
	
	for drop in _drops_array:
		if rand < drop.CHANCE:
			return [drop.ITEM_ID, drop.AMOUNT]
		rand -= drop.CHANCE
	
	return [-1, 0]


#var d = [
			#{"ITEM_ID": -1, "AMOUNT": 0, "CHANCE": 8},
			#{"ITEM_ID": 4, "AMOUNT": 1, "CHANCE": 5},
			#{"ITEM_ID": 4, "AMOUNT": 2, "CHANCE": 5},
			#{"ITEM_ID": 4, "AMOUNT": 3, "CHANCE": 4},
			#{"ITEM_ID": 168, "AMOUNT": 1, "CHANCE": 0.02},
			#{"ITEM_ID": -100, "AMOUNT": 5, "CHANCE": 1},
			#{"ITEM_ID": -100, "AMOUNT": 10, "CHANCE": 1},
			#{"ITEM_ID": -100, "AMOUNT": 15, "CHANCE": 1},
			#{"ITEM_ID": -100, "AMOUNT": 20, "CHANCE": 1}
		#]
#
#func _ready() -> void:
	#for i in 10000:
		#var drop = WeightedRandom(d)
		#if drop[0] == 168:
			#print('uep')
