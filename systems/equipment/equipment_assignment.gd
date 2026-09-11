class_name EquipmentAssignment
extends RefCounted

var _by_character_id: Dictionary = {}

func equip(character_id: String, equipment_id: String) -> void:
	_by_character_id[character_id] = equipment_id

func unequip(character_id: String) -> void:
	_by_character_id.erase(character_id)

func equipped_equipment_id(character_id: String) -> String:
	return str(_by_character_id.get(character_id, ""))

func has_equipment(character_id: String) -> bool:
	return _by_character_id.has(character_id)
