extends Node

const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")
const StageProgressionScript = preload("res://systems/progression/stage_progression.gd")
const CombatSessionScript = preload("res://systems/combat/combat_session.gd")
const CharacterDefinitionScript = preload("res://systems/characters/character_definition.gd")
const CharacterStateScript = preload("res://systems/characters/character_state.gd")
const CharacterStatServiceScript = preload("res://systems/characters/character_stat_service.gd")
const EquipmentDefinitionScript = preload("res://systems/equipment/equipment_definition.gd")
const EquipmentStateScript = preload("res://systems/equipment/equipment_state.gd")
const EquipmentAssignmentScript = preload("res://systems/equipment/equipment_assignment.gd")
const EquipmentStatServiceScript = preload("res://systems/equipment/equipment_stat_service.gd")
const EquipmentUpgradeServiceScript = preload("res://systems/equipment/equipment_upgrade_service.gd")
const ReturnStateScript = preload("res://systems/return/return_state.gd")
const ReturnServiceScript = preload("res://systems/return/return_service.gd")
const ShardInventoryScript = preload("res://systems/shards/shard_inventory.gd")
const ShardServiceScript = preload("res://systems/shards/shard_service.gd")
const ShardDefinitionScript = preload("res://systems/shards/shard_definition.gd")
const GachaPoolScript = preload("res://systems/gacha/gacha_pool.gd")
const GachaInventoryScript = preload("res://systems/gacha/gacha_inventory.gd")
const GachaServiceScript = preload("res://systems/gacha/gacha_service.gd")
const SaveServiceScript = preload("res://systems/save/save_service.gd")
const OfflineServiceScript = preload("res://systems/offline/offline_service.gd")
const TeamStateScript = preload("res://systems/teams/team_state.gd")

signal stage_changed(stage: int)

var stage_progression
var combat_session
var character_stat_service
var equipment_stat_service
var equipment_upgrade_service
var shard_service
var shard_inventory
var return_state
var return_service
var gacha_service
var gacha_inventory
var save_service
var offline_service
var team_state
var character_gacha_pool
var equipment_gacha_pool
var debug_character_definitions: Array = []
var debug_character_states: Array = []
var debug_equipment_definitions: Dictionary = {}
var debug_equipment_states: Dictionary = {}
var equipment_assignment

func _ready() -> void:
	var registry = get_node_or_null("/root/DataRegistry")
	var formula = StageFormulaScript.new()
	if registry != null:
		formula = registry.create_stage_formula()
	stage_progression = StageProgressionScript.new(formula)
	stage_progression.stage_changed.connect(_on_stage_changed)
	character_stat_service = CharacterStatServiceScript.new()
	equipment_stat_service = EquipmentStatServiceScript.new()
	equipment_upgrade_service = EquipmentUpgradeServiceScript.new()
	shard_service = ShardServiceScript.new()
	shard_inventory = ShardInventoryScript.new(shard_service.inventory_cap())
	return_state = ReturnStateScript.new()
	return_state.snacks = 500
	return_state.parts = 500
	return_state.shard_upgrade_material = 100
	return_state.stones = 500
	return_service = ReturnServiceScript.new()
	gacha_service = GachaServiceScript.new()
	gacha_inventory = GachaInventoryScript.new()
	save_service = SaveServiceScript.new()
	offline_service = OfflineServiceScript.new()
	character_gacha_pool = GachaPoolScript.default_character_pool()
	equipment_gacha_pool = GachaPoolScript.default_equipment_pool()
	equipment_assignment = EquipmentAssignmentScript.new()
	_create_debug_characters()
	team_state = TeamStateScript.new(_debug_character_ids())
	_create_debug_equipment()
	_create_debug_shards()
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())

func _process(delta: float) -> void:
	tick_combat(delta)

func defeat_normal_enemy() -> void:
	stage_progression.defeat_normal_enemy()

func tick_combat(delta: float) -> void:
	combat_session.tick(delta)

func current_stage() -> int:
	return stage_progression.current_stage

func current_enemy_hp() -> float:
	return stage_progression.current_enemy_hp

func current_enemy_type() -> String:
	return stage_progression.current_enemy_type

func boss_time_remaining() -> float:
	return combat_session.boss_time_remaining

func set_auto_boss_retry_enabled(enabled: bool) -> void:
	stage_progression.auto_boss_retry_enabled = enabled

func can_return() -> bool:
	return return_service.can_return(return_state, stage_progression.highest_stage_in_run)

func perform_return() -> Dictionary:
	return return_service.perform_return(return_state, stage_progression)

func milestone_damage_percent() -> float:
	return return_service.milestone_damage_percent(return_state)

func pull_character_gacha(count: int) -> Dictionary:
	return _pull_gacha(character_gacha_pool, count)

func pull_equipment_gacha(count: int) -> Dictionary:
	return _pull_gacha(equipment_gacha_pool, count)

func create_save_data() -> Dictionary:
	return save_service.create_save(
		stage_progression,
		return_state,
		debug_character_states,
		debug_equipment_states,
		equipment_assignment,
		gacha_inventory,
		shard_inventory,
		team_state
	)

func apply_save_data(save_data: Dictionary) -> Dictionary:
	var result = save_service.apply_save(
		save_data,
		stage_progression,
		return_state,
		debug_character_states,
		debug_equipment_states,
		equipment_assignment,
		gacha_inventory,
		shard_inventory,
		team_state
	)
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return result

func select_team_slot(slot_index: int) -> void:
	team_state.select_slot(slot_index)
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())

func set_team_member(member_index: int, character_id: String) -> Dictionary:
	if not _debug_character_definitions_by_id().has(character_id):
		return {"success": false, "reason": "unknown_character"}
	var members = team_state.current_members()
	for index in range(0, members.size()):
		if index != member_index and members[index] == character_id:
			return {"success": false, "reason": "duplicate_character"}
	team_state.set_member(team_state.selected_team_slot, member_index, character_id)
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return {"success": true}

func level_up_character(character_id: String) -> Dictionary:
	var definitions = _debug_character_definitions_by_id()
	var states = _debug_character_states_by_id()
	if not definitions.has(character_id) or not states.has(character_id):
		return {"success": false, "reason": "unknown_character"}
	var state = states[character_id]
	var cost = character_stat_service.level_up_cost(state.level)
	if cost <= 0:
		return {"success": false, "reason": "max_level", "cost": 0}
	if return_state.snacks < cost:
		return {"success": false, "reason": "not_enough_snacks", "cost": cost}
	return_state.snacks -= cost
	state.set_level(state.level + 1)
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return {"success": true, "cost": cost, "level": state.level}

func upgrade_equipment(equipment_id: String) -> Dictionary:
	if not debug_equipment_states.has(equipment_id):
		return {"success": false, "reason": "unknown_equipment"}
	var state = debug_equipment_states[equipment_id]
	var cost = equipment_upgrade_service.next_attempt_cost(state)
	if cost <= 0:
		return {"success": false, "reason": "max_level", "cost": 0}
	if return_state.parts < cost:
		return {"success": false, "reason": "not_enough_parts", "cost": cost}
	return_state.parts -= cost
	var result = equipment_upgrade_service.attempt_upgrade(state)
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return result

func equip_item(character_id: String, equipment_id: String) -> Dictionary:
	if not _debug_character_definitions_by_id().has(character_id):
		return {"success": false, "reason": "unknown_character"}
	if not debug_equipment_states.has(equipment_id):
		return {"success": false, "reason": "unknown_equipment"}
	for existing_character_id in equipment_assignment._by_character_id.keys():
		if existing_character_id != character_id and equipment_assignment._by_character_id[existing_character_id] == equipment_id:
			equipment_assignment.unequip(str(existing_character_id))
	equipment_assignment.equip(character_id, equipment_id)
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return {"success": true}

func set_equipment_shard(equipment_id: String, socket_index: int, shard_id: String) -> Dictionary:
	if not debug_equipment_states.has(equipment_id):
		return {"success": false, "reason": "unknown_equipment"}
	if shard_id != "" and not shard_inventory.has_shard(shard_id):
		return {"success": false, "reason": "unknown_shard"}
	for other_equipment_id in debug_equipment_states.keys():
		var other_state = debug_equipment_states[other_equipment_id]
		for index in range(0, other_state.shard_socket_ids.size()):
			if other_equipment_id != equipment_id and other_state.shard_socket_ids[index] == shard_id:
				other_state.set_shard_socket(index, "")
	var state = debug_equipment_states[equipment_id]
	state.set_shard_socket(socket_index, shard_id)
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return {"success": true}

func upgrade_shard(shard_id: String) -> Dictionary:
	if not shard_inventory.has_shard(shard_id):
		return {"success": false, "reason": "unknown_shard"}
	var shard = shard_inventory.get_shard(shard_id)
	var cost = shard_service.upgrade_cost(shard.level + 1)
	if cost <= 0:
		return {"success": false, "reason": "max_level", "cost": 0}
	if return_state.shard_upgrade_material < cost:
		return {"success": false, "reason": "not_enough_shard_material", "cost": cost}
	return_state.shard_upgrade_material -= cost
	var result = shard_service.upgrade_shard(shard)
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return result

func save_to_path(path: String) -> bool:
	return save_service.save_to_path(path, create_save_data())

func load_from_path(path: String) -> Dictionary:
	var save_data = save_service.load_from_path(path)
	if save_data.is_empty():
		return {"success": false, "reason": "load_failed"}
	var result = apply_save_data(save_data)
	result["offline_rewards"] = apply_offline_from_save(save_data)
	return result

func apply_offline_from_save(save_data: Dictionary) -> Dictionary:
	return offline_service.apply_from_save_time(return_state, save_data, Time.get_unix_time_from_system(), stage_progression.current_stage)

func apply_offline_seconds(elapsed_seconds: float) -> Dictionary:
	return offline_service.apply_offline(return_state, elapsed_seconds, stage_progression.current_stage)

func _on_stage_changed(stage: int) -> void:
	stage_changed.emit(stage)

func _pull_gacha(pool, count: int) -> Dictionary:
	var cost = gacha_service.cost_for_pulls(count)
	if return_state.stones < cost:
		return {"success": false, "reason": "not_enough_stones", "cost": cost}

	var results: Array = []
	if count == 10:
		results = gacha_service.pull_ten(pool)
	else:
		for index in range(0, count):
			results.append(gacha_service.pull_one(pool))

	return_state.stones -= cost
	gacha_service.apply_results(gacha_inventory, results)
	return {
		"success": true,
		"cost": cost,
		"results": results
	}

func _create_debug_party() -> Array:
	var party: Array = []
	var definitions_by_id = _debug_character_definitions_by_id()
	var states_by_id = _debug_character_states_by_id()
	for character_id in team_state.current_members():
		if not definitions_by_id.has(character_id):
			continue
		if not states_by_id.has(character_id):
			continue
		var definition = definitions_by_id[character_id]
		var state = states_by_id[character_id]
		var equipment_modifiers = _equipment_modifiers_for_character(definition.character_id)
		party.append(character_stat_service.combat_state(definition, state, equipment_modifiers))
	return party

func _create_debug_characters() -> void:
	debug_character_definitions = [
		CharacterDefinitionScript.new("debug_ssr_fire", "SSR", "fire", "pure_dps", 1.0, "ひなた"),
		CharacterDefinitionScript.new("debug_sr_water", "SR", "water", "pure_dps", 1.0, "しずく"),
		CharacterDefinitionScript.new("debug_r_grass", "R", "grass", "pure_dps", 1.0, "こはる"),
		CharacterDefinitionScript.new("debug_n_none", "N", "none", "pure_dps", 1.0, "まめ")
	]
	debug_character_states = [
		CharacterStateScript.new("debug_ssr_fire", 1, 0),
		CharacterStateScript.new("debug_sr_water", 1, 0),
		CharacterStateScript.new("debug_r_grass", 1, 0),
		CharacterStateScript.new("debug_n_none", 1, 0)
	]

func _debug_character_ids() -> Array:
	var ids: Array = []
	for definition in debug_character_definitions:
		ids.append(definition.character_id)
	return ids

func _debug_character_definitions_by_id() -> Dictionary:
	var data = {}
	for definition in debug_character_definitions:
		data[definition.character_id] = definition
	return data

func _debug_character_states_by_id() -> Dictionary:
	var data = {}
	for state in debug_character_states:
		data[state.character_id] = state
	return data

func _create_debug_equipment() -> void:
	debug_equipment_definitions = {
		"debug_ssr_blade": EquipmentDefinitionScript.new("debug_ssr_blade", "SSR", "attack", "星灯りのつえ"),
		"debug_sr_blade": EquipmentDefinitionScript.new("debug_sr_blade", "SR", "attack", "水玉のベル"),
		"debug_r_blade": EquipmentDefinitionScript.new("debug_r_blade", "R", "attack", "若葉のピン"),
		"debug_n_blade": EquipmentDefinitionScript.new("debug_n_blade", "N", "attack", "ちいさな木刀")
	}
	debug_equipment_states = {
		"debug_ssr_blade": EquipmentStateScript.new("debug_ssr_blade", 1),
		"debug_sr_blade": EquipmentStateScript.new("debug_sr_blade", 1),
		"debug_r_blade": EquipmentStateScript.new("debug_r_blade", 1),
		"debug_n_blade": EquipmentStateScript.new("debug_n_blade", 1)
	}
	equipment_assignment.equip("debug_ssr_fire", "debug_ssr_blade")
	equipment_assignment.equip("debug_sr_water", "debug_sr_blade")
	equipment_assignment.equip("debug_r_grass", "debug_r_blade")
	equipment_assignment.equip("debug_n_none", "debug_n_blade")

func _create_debug_shards() -> void:
	shard_inventory.add_shard(shard_service.create_shard("mock_shard_attack", "SSR", ShardDefinitionScript.STAT_ATTACK_PERCENT, ShardDefinitionScript.STAT_CRIT_RATE, 3.3, 0.06))
	shard_inventory.add_shard(shard_service.create_shard("mock_shard_speed", "SSR", ShardDefinitionScript.STAT_ATTACK_SPEED_PERCENT, ShardDefinitionScript.STAT_ATTACK_PERCENT, 0.22, 1.2))
	shard_inventory.add_shard(shard_service.create_shard("mock_shard_element", "SSR", ShardDefinitionScript.STAT_ELEMENT_DAMAGE_PERCENT, ShardDefinitionScript.STAT_CRIT_DAMAGE, 0.45, 0.24))
	debug_equipment_states["debug_ssr_blade"].set_shard_socket(0, "mock_shard_attack")
	debug_equipment_states["debug_ssr_blade"].set_shard_socket(1, "mock_shard_speed")

func _equipment_modifiers_for_character(character_id: String) -> Dictionary:
	var equipment_id = equipment_assignment.equipped_equipment_id(character_id)
	if equipment_id == "":
		return {}
	if not debug_equipment_definitions.has(equipment_id):
		return {}
	if not debug_equipment_states.has(equipment_id):
		return {}
	var shard_modifiers = shard_service.equipped_modifiers(debug_equipment_states[equipment_id], shard_inventory)
	var modifiers = equipment_stat_service.combined_stat_modifiers(debug_equipment_definitions[equipment_id], debug_equipment_states[equipment_id], shard_modifiers)
	modifiers["milestone_damage_percent"] = milestone_damage_percent()
	return modifiers
