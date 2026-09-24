class_name StatCalculator
extends RefCounted

const CharacterStatServiceScript = preload("res://systems/characters/character_stat_service.gd")
const EquipmentStateScript = preload("res://systems/equipment/equipment_state.gd")
const EquipmentStatServiceScript = preload("res://systems/equipment/equipment_stat_service.gd")
const ShardServiceScript = preload("res://systems/shards/shard_service.gd")

var character_stat_service
var equipment_stat_service
var shard_service

func _init() -> void:
	character_stat_service = CharacterStatServiceScript.new()
	equipment_stat_service = EquipmentStatServiceScript.new()
	shard_service = ShardServiceScript.new()

func base_attack(character_definition, character_state) -> float:
	return character_stat_service.base_attack(character_definition, character_state)

func equipment_modifiers(equipment_definition, equipment_state, shard_inventory = null) -> Dictionary:
	var shard_modifiers = {}
	if shard_inventory != null:
		shard_modifiers = shard_service.equipped_modifiers(equipment_state, shard_inventory)
	return equipment_stat_service.combined_stat_modifiers(equipment_definition, equipment_state, shard_modifiers)

func combat_state(character_definition, character_state, equipment_definition = null, equipment_state = null, shard_inventory = null, milestone_damage_percent: float = 0.0):
	var modifiers = {}
	if equipment_definition != null and equipment_state != null:
		modifiers = equipment_modifiers(equipment_definition, equipment_state, shard_inventory)
	modifiers["milestone_damage_percent"] = milestone_damage_percent
	return character_stat_service.combat_state(character_definition, character_state, modifiers)

func socket_stat_delta(equipment_definition, equipment_state, shard_inventory, socket_index: int, shard_id: String) -> Dictionary:
	if socket_index < 0 or socket_index >= EquipmentStateScript.SHARD_SOCKET_COUNT:
		return {"success": false, "reason": "socket_out_of_range"}
	var before = equipment_modifiers(equipment_definition, equipment_state, shard_inventory)
	var preview = EquipmentStateScript.new(equipment_state.equipment_id, equipment_state.level, equipment_state.definition_id)
	for index in range(0, EquipmentStateScript.SHARD_SOCKET_COUNT):
		preview.set_shard_socket(index, str(equipment_state.shard_socket_ids[index]))
	preview.set_shard_socket(socket_index, shard_id)
	var after = equipment_modifiers(equipment_definition, preview, shard_inventory)
	return {
		"success": true,
		"before": before,
		"after": after,
		"delta": _delta(before, after)
	}

func _delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var result = {}
	for stat_id in before.keys():
		result[stat_id] = float(result.get(stat_id, 0.0)) - float(before[stat_id])
	for stat_id in after.keys():
		result[stat_id] = float(result.get(stat_id, 0.0)) + float(after[stat_id])
	return result
