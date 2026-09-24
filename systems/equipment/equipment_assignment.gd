class_name EquipmentAssignment
extends RefCounted

var _by_character_id: Dictionary = {}

func equip(character_id: String, equipment_id: String) -> void:
	_by_character_id[character_id] = equipment_id

func unequip(character_id: String) -> void:
	_by_character_id.erase(character_id)

func unequip_equipment(equipment_id: String) -> void:
	for character_id in _by_character_id.keys():
		if str(_by_character_id[character_id]) == equipment_id:
			_by_character_id.erase(character_id)
			return

func equipped_equipment_id(character_id: String) -> String:
	return str(_by_character_id.get(character_id, ""))

func has_equipment(character_id: String) -> bool:
	return _by_character_id.has(character_id)

func equipped_character_id(equipment_id: String) -> String:
	for character_id in _by_character_id.keys():
		if str(_by_character_id[character_id]) == equipment_id:
			return str(character_id)
	return ""

func is_equipment_equipped(equipment_id: String) -> bool:
	return equipped_character_id(equipment_id) != ""
