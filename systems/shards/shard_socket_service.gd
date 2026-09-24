class_name ShardSocketService
extends RefCounted

const EquipmentStateScript = preload("res://systems/equipment/equipment_state.gd")

func socket_shard(equipment_states: Dictionary, shard_inventory, equipment_id: String, socket_index: int, shard_id: String) -> Dictionary:
	var validation = _validate_target(equipment_states, shard_inventory, equipment_id, socket_index, shard_id)
	if not bool(validation.get("success", false)):
		return validation
	var location = find_shard_location(equipment_states, shard_id)
	if not location.is_empty():
		return {"success": false, "reason": "duplicate_shard"}
	equipment_states[equipment_id].set_shard_socket(socket_index, shard_id)
	return {"success": true}

func detach_shard(equipment_states: Dictionary, equipment_id: String, socket_index: int) -> Dictionary:
	if not equipment_states.has(equipment_id):
		return {"success": false, "reason": "unknown_equipment"}
	if socket_index < 0 or socket_index >= EquipmentStateScript.SHARD_SOCKET_COUNT:
		return {"success": false, "reason": "socket_out_of_range"}
	equipment_states[equipment_id].set_shard_socket(socket_index, "")
	return {"success": true}

func move_shard(equipment_states: Dictionary, shard_inventory, equipment_id: String, socket_index: int, shard_id: String) -> Dictionary:
	var validation = _validate_target(equipment_states, shard_inventory, equipment_id, socket_index, shard_id)
	if not bool(validation.get("success", false)):
		return validation
	var location = find_shard_location(equipment_states, shard_id)
	if not location.is_empty():
		var source_equipment_id = str(location.get("equipment_id", ""))
		var source_socket_index = int(location.get("socket_index", -1))
		if source_equipment_id == equipment_id and source_socket_index == socket_index:
			return {"success": true}
		equipment_states[source_equipment_id].set_shard_socket(source_socket_index, "")
	equipment_states[equipment_id].set_shard_socket(socket_index, shard_id)
	return {"success": true}

func find_shard_location(equipment_states: Dictionary, shard_id: String) -> Dictionary:
	if shard_id == "":
		return {}
	for equipment_id in equipment_states.keys():
		var state = equipment_states[equipment_id]
		for index in range(0, state.shard_socket_ids.size()):
			if str(state.shard_socket_ids[index]) == shard_id:
				return {"equipment_id": str(equipment_id), "socket_index": index}
	return {}

func _validate_target(equipment_states: Dictionary, shard_inventory, equipment_id: String, socket_index: int, shard_id: String) -> Dictionary:
	if not equipment_states.has(equipment_id):
		return {"success": false, "reason": "unknown_equipment"}
	if socket_index < 0 or socket_index >= EquipmentStateScript.SHARD_SOCKET_COUNT:
		return {"success": false, "reason": "socket_out_of_range"}
	if shard_id == "":
		return {"success": false, "reason": "empty_shard"}
	if shard_inventory == null or not shard_inventory.has_shard(shard_id):
		return {"success": false, "reason": "unknown_shard"}
	return {"success": true}
