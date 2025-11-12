extends Node

var ItemData: Dictionary
var ShopData: Dictionary
var CraftingRecipes: Array
var GrindingRecipes: Array

func _ready() -> void:
	var ItemDataFile = FileAccess.open("res://Data/ItemData.json", FileAccess.READ)
	ItemData = JSON.parse_string(ItemDataFile.get_as_text())
	
	var ShopDataFile = FileAccess.open("res://Data/ShopData.json", FileAccess.READ)
	ShopData = JSON.parse_string(ShopDataFile.get_as_text())
	
	var CraftingRecipeFile = FileAccess.open("res://Data/CraftingRecipes.json", FileAccess.READ)
	CraftingRecipes = JSON.parse_string(CraftingRecipeFile.get_as_text())
	
	var GrindingRecipesFile = FileAccess.open("res://Data/GrindingRecipes.json", FileAccess.READ)
	GrindingRecipes = JSON.parse_string(GrindingRecipesFile.get_as_text())


func GetRecipe(_item1_id: int, _item2_id: int, _item1_amount: int, _item2_amount: int) -> Dictionary:
	
	# Create results array
	var results: Array = []
	
	# Insert all recipes which have item 1 & 2 id
	for recipe in CraftingRecipes:
		if recipe.INGREDIENT_1[0] == _item1_id and recipe.INGREDIENT_2[0] == _item2_id:
			results.append(recipe)
	
	if results.size() == 0: return {}
	
	# Calculate amount
	# I hope to fucking god i implemented this correctly
	var recipe: Dictionary = results[0]
	var item1_mult: int = floor(_item1_amount / recipe.INGREDIENT_1[1])
	var item2_mult: int = floor(_item2_amount / recipe.INGREDIENT_2[1])

	var amount: int = min(item1_mult, item2_mult)

	recipe.AMOUNT = amount
	
	# Return result
	return recipe


func GetGrind(_item_id: int, _item_amount: int) -> Dictionary:
	
	# Create results array
	var results: Array = []
	
	# Insert all recipes which have item 1 & 2 id
	for recipe in GrindingRecipes:
		if recipe.INGREDIENT[0] == _item_id:
			results.append(recipe)
	
	if results.size() == 0: return {}
	
	# Calculate amount
	var recipe: Dictionary = results[0]
	var amount: int = floor(_item_amount / recipe.INGREDIENT[1])
	recipe.AMOUNT = amount
	
	# Return result
	return recipe
