class_name SaveService
extends RefCounted

const SCHEMA_VERSION = 1

const CharacterStateScript = preload("res://systems/characters/character_state.gd")
const EquipmentStateScript = preload("res://systems/equipment/equipment_state.gd")
const ShardStateScript = preload("res://systems/shards/shard_state.gd")
const TeamStateScript = preload("res://systems/teams/team_state.gd")

func create_save(stage_progression, return_state, character_states: Array, equipment_states: Dictionary, equipment_assignment, gacha_inventory, shard_inventory = null, team_state = null) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"current_stage": stage_progression.current_stage,
		"current_run_highest_stage": stage_progression.highest_stage_in_run,
		"auto_retry_boss": stage_progression.auto_boss_retry_enabled,
		"return_count": return_state.return_count,
		"snacks": return_state.snacks,
		"parts": return_state.parts,
		"shard_upgrade_material": return_state.shard_upgrade_material,
		"shard_acquisition_budget": return_state.shard_acquisition_budget,
		"hikari_stone": return_state.stones,
		"claimed_100_stage_stone_flags": return_state.claimed_return_stages.duplicate(true),
		"claimed_500_stage_milestones": return_state.claimed_milestones.duplicate(true),
		"owned_characters": _serialize_character_states(character_states),
		"owned_equipments": _serialize_equipment_states(equipment_states),
		"equipment_assignments": equipment_assignment._by_character_id.duplicate(true),
		"selected_team_slot": _selected_team_slot(team_state),
		"teams": _serialize_teams(team_state),
		"gacha_inventory": {
			"owned_characters": gacha_inventory.owned_characters.duplicate(true),
			"character_duplicate_tokens": gacha_inventory.character_duplicate_tokens.duplicate(true),
			"owned_equipment_counts": gacha_inventory.owned_equipment_counts.duplicate(true)
		},
		"shard_instances": _serialize_shard_inventory(shard_inventory),
		"last_save_time": Time.get_unix_time_from_system(),
		"last_active_time": Time.get_unix_time_from_system()
	}

func apply_save(save_data: Dictionary, stage_progression, return_state, character_states: Array, equipment_states: Dictionary, equipment_assignment, gacha_inventory, shard_inventory = null, team_state = null) -> Dictionary:
	var warnings: Array = []
	if int(save_data.get("schema_version", 0)) > SCHEMA_VERSION:
		warnings.append("save schema is newer than supported")

	stage_progression.auto_boss_retry_enabled = bool(save_data.get("auto_retry_boss", true))
	stage_progression.set_stage(_positive_int(save_data.get("current_stage", 1), 1))
	stage_progression.highest_stage_in_run = max(stage_progression.current_stage, _positive_int(save_data.get("current_run_highest_stage", stage_progression.current_stage), stage_progression.current_stage))

	return_state.return_count = max(0, int(save_data.get("return_count", 0)))
	return_state.snacks = max(0, int(save_data.get("snacks", 0)))
	return_state.parts = max(0, int(save_data.get("parts", 0)))
	return_state.shard_upgrade_material = max(0, int(save_data.get("shard_upgrade_material", 0)))
	return_state.shard_acquisition_budget = max(0.0, float(save_data.get("shard_acquisition_budget", 0.0)))
	return_state.stones = max(0, int(save_data.get("hikari_stone", 0)))
	return_state.claimed_return_stages = _sanitize_stage_flags(save_data.get("claimed_100_stage_stone_flags", {}), 100)
	return_state.claimed_milestones = _sanitize_stage_flags(save_data.get("claimed_500_stage_milestones", {}), 500)

	_apply_character_states(save_data.get("owned_characters", {}), character_states, warnings)
	_apply_equipment_states(save_data.get("owned_equipments", {}), equipment_states, warnings)
	equipment_assignment._by_character_id = _sanitize_equipment_assignments(save_data.get("equipment_assignments", {}), equipment_states, warnings)
	if team_state != null:
		_apply_teams(save_data.get("teams", []), save_data.get("selected_team_slot", 0), team_state, character_states, warnings)
	_apply_gacha_inventory(save_data.get("gacha_inventory", {}), gacha_inventory)
	if shard_inventory != null:
		_apply_shards(save_data.get("shard_instances", {}), shard_inventory, warnings)

	return {"success": true, "warnings": warnings}

func save_to_path(path: String, save_data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(save_data))
	return true

func load_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _serialize_character_states(character_states: Array) -> Dictionary:
	var data = {}
	for state in character_states:
		data[state.character_id] = {
			"level": state.level,
			"najimi": state.najimi
		}
	return data

func _serialize_equipment_states(equipment_states: Dictionary) -> Dictionary:
	var data = {}
	for equipment_id in equipment_states.keys():
		var state = equipment_states[equipment_id]
		data[equipment_id] = {
			"level": state.level,
			"shard_socket_ids": state.shard_socket_ids.duplicate(true)
		}
	return data

func _serialize_shard_inventory(shard_inventory) -> Dictionary:
	var data = {}
	if shard_inventory == null:
		return data
	for shard_id in shard_inventory.shards.keys():
		var shard = shard_inventory.shards[shard_id]
		data[shard_id] = {
			"rarity": shard.rarity,
			"main_stat": shard.main_stat,
			"sub_stat": shard.sub_stat,
			"initial_main_value": shard.initial_main_value,
			"initial_sub_value": shard.initial_sub_value,
			"current_main_value": shard.current_main_value,
			"current_sub_value": shard.current_sub_value,
			"level": shard.level,
			"growth_history": shard.growth_history.duplicate(true)
		}
	return data

func _selected_team_slot(team_state) -> int:
	if team_state == null:
		return 0
	return team_state.selected_team_slot

func _serialize_teams(team_state) -> Array:
	var data: Array = []
	if team_state == null:
		return data
	for slot in range(0, TeamStateScript.TEAM_SLOT_COUNT):
		data.append(team_state.team_members(slot))
	return data

func _apply_character_states(data, character_states: Array, warnings: Array) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		warnings.append("owned_characters was not a dictionary")
		return
	var states_by_id = {}
	for state in character_states:
		states_by_id[state.character_id] = state
	for character_id in data.keys():
		if not states_by_id.has(character_id):
			warnings.append("unknown character id: %s" % str(character_id))
			continue
		var source = data[character_id]
		if typeof(source) != TYPE_DICTIONARY:
			continue
		states_by_id[character_id].set_level(int(source.get("level", 1)))
		states_by_id[character_id].set_najimi(int(source.get("najimi", 0)))

func _apply_equipment_states(data, equipment_states: Dictionary, warnings: Array) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		warnings.append("owned_equipments was not a dictionary")
		return
	for equipment_id in data.keys():
		if not equipment_states.has(equipment_id):
			warnings.append("unknown equipment id: %s" % str(equipment_id))
			continue
		var source = data[equipment_id]
		if typeof(source) != TYPE_DICTIONARY:
			continue
		var state = equipment_states[equipment_id]
		state.set_level(int(source.get("level", 1)))
		var sockets = source.get("shard_socket_ids", ["", "", ""])
		if typeof(sockets) == TYPE_ARRAY:
			for index in range(0, min(sockets.size(), EquipmentStateScript.SHARD_SOCKET_COUNT)):
				state.set_shard_socket(index, str(sockets[index]))

func _sanitize_equipment_assignments(data, equipment_states: Dictionary, warnings: Array) -> Dictionary:
	var sanitized = {}
	if typeof(data) != TYPE_DICTIONARY:
		warnings.append("equipment_assignments was not a dictionary")
		return sanitized
	var assigned_equipment = {}
	for character_id in data.keys():
		var equipment_id = str(data[character_id])
		if equipment_id == "":
			continue
		if not equipment_states.has(equipment_id):
			warnings.append("assignment references unknown equipment: %s" % equipment_id)
			continue
		if assigned_equipment.has(equipment_id):
			warnings.append("duplicate equipment assignment ignored: %s" % equipment_id)
			continue
		assigned_equipment[equipment_id] = true
		sanitized[str(character_id)] = equipment_id
	return sanitized

func _apply_gacha_inventory(data, gacha_inventory) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	gacha_inventory.owned_characters = _sanitize_bool_dict(data.get("owned_characters", {}))
	gacha_inventory.character_duplicate_tokens = _sanitize_non_negative_int_dict(data.get("character_duplicate_tokens", {}))
	gacha_inventory.owned_equipment_counts = _sanitize_non_negative_int_dict(data.get("owned_equipment_counts", {}))

func _apply_teams(data, selected_slot, team_state, character_states: Array, warnings: Array) -> void:
	var valid_character_ids = {}
	for state in character_states:
		valid_character_ids[state.character_id] = true

	if typeof(data) != TYPE_ARRAY:
		warnings.append("teams was not an array")
		return

	for slot in range(0, min(data.size(), TeamStateScript.TEAM_SLOT_COUNT)):
		var source_members = data[slot]
		if typeof(source_members) != TYPE_ARRAY:
			warnings.append("team slot was not an array: %d" % slot)
			continue
		var members: Array = []
		for member in source_members:
			var character_id = str(member)
			if character_id == "":
				continue
			if not valid_character_ids.has(character_id):
				warnings.append("team references unknown character: %s" % character_id)
				continue
			if members.has(character_id):
				warnings.append("duplicate team member ignored: %s" % character_id)
				continue
			members.append(character_id)
		team_state.set_team_members(slot, members)
	team_state.select_slot(int(selected_slot))

func _apply_shards(data, shard_inventory, warnings: Array) -> void:
	shard_inventory.shards.clear()
	if typeof(data) != TYPE_DICTIONARY:
		warnings.append("shard_instances was not a dictionary")
		return
	for shard_id in data.keys():
		var source = data[shard_id]
		if typeof(source) != TYPE_DICTIONARY:
			continue
		var main_stat = str(source.get("main_stat", ""))
		var sub_stat = str(source.get("sub_stat", ""))
		if main_stat == sub_stat:
			warnings.append("invalid shard main/sub ignored: %s" % str(shard_id))
			continue
		var shard = ShardStateScript.new(
			str(shard_id),
			str(source.get("rarity", "SSR")),
			main_stat,
			sub_stat,
			max(0.0, float(source.get("initial_main_value", 0.0))),
			max(0.0, float(source.get("initial_sub_value", 0.0)))
		)
		shard.level = clamp(int(source.get("level", 1)), ShardStateScript.MIN_LEVEL, ShardStateScript.MAX_LEVEL)
		shard.current_main_value = max(0.0, float(source.get("current_main_value", shard.initial_main_value)))
		shard.current_sub_value = max(0.0, float(source.get("current_sub_value", shard.initial_sub_value)))
		shard.growth_history = source.get("growth_history", [])
		shard_inventory.add_shard(shard)

func _sanitize_stage_flags(data, step: int) -> Dictionary:
	var sanitized = {}
	if typeof(data) != TYPE_DICTIONARY:
		return sanitized
	for stage_key in data.keys():
		var stage = int(stage_key)
		if stage > 0 and stage <= 5000 and stage % step == 0 and bool(data[stage_key]):
			sanitized[stage] = true
	return sanitized

func _sanitize_bool_dict(data) -> Dictionary:
	var sanitized = {}
	if typeof(data) != TYPE_DICTIONARY:
		return sanitized
	for key in data.keys():
		if bool(data[key]):
			sanitized[str(key)] = true
	return sanitized

func _sanitize_non_negative_int_dict(data) -> Dictionary:
	var sanitized = {}
	if typeof(data) != TYPE_DICTIONARY:
		return sanitized
	for key in data.keys():
		sanitized[str(key)] = max(0, int(data[key]))
	return sanitized

func _positive_int(value, fallback: int) -> int:
	var parsed = int(value)
	if parsed < 1:
		return fallback
	return parsed
