class_name EquipmentService
extends RefCounted

func equip_to_character(character_id: String, equipment_id: String, valid_character_ids: Dictionary, equipment_states: Dictionary, assignment) -> Dictionary:
	if not valid_character_ids.has(character_id):
		return {"success": false, "reason": "unknown_character"}
	if not equipment_states.has(equipment_id):
		return {"success": false, "reason": "unknown_equipment"}
	assignment.unequip_equipment(equipment_id)
	assignment.equip(character_id, equipment_id)
	return {"success": true}

func unequip_from_character(character_id: String, valid_character_ids: Dictionary, assignment) -> Dictionary:
	if not valid_character_ids.has(character_id):
		return {"success": false, "reason": "unknown_character"}
	assignment.unequip(character_id)
	return {"success": true}
