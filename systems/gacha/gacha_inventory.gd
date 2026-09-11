class_name GachaInventory
extends RefCounted

const GachaPoolScript = preload("res://systems/gacha/gacha_pool.gd")

var owned_characters: Dictionary = {}
var character_duplicate_tokens: Dictionary = {}
var owned_equipment_counts: Dictionary = {}

func add_result(result: Dictionary) -> void:
	var category = str(result.get("category", ""))
	var item_id = str(result.get("item_id", ""))
	if category == GachaPoolScript.CATEGORY_CHARACTER:
		if owned_characters.has(item_id):
			character_duplicate_tokens[item_id] = int(character_duplicate_tokens.get(item_id, 0)) + 1
		else:
			owned_characters[item_id] = true
			character_duplicate_tokens[item_id] = int(character_duplicate_tokens.get(item_id, 0))
		return

	if category == GachaPoolScript.CATEGORY_EQUIPMENT:
		owned_equipment_counts[item_id] = int(owned_equipment_counts.get(item_id, 0)) + 1

func has_character(character_id: String) -> bool:
	return owned_characters.has(character_id)

func character_duplicate_count(character_id: String) -> int:
	return int(character_duplicate_tokens.get(character_id, 0))

func equipment_count(equipment_id: String) -> int:
	return int(owned_equipment_counts.get(equipment_id, 0))
