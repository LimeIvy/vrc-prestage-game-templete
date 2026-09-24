extends Node

const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")
const StageProgressionScript = preload("res://systems/progression/stage_progression.gd")
const CombatSessionScript = preload("res://systems/combat/combat_session.gd")
const CharacterDefinitionScript = preload("res://systems/characters/character_definition.gd")
const CharacterStateScript = preload("res://systems/characters/character_state.gd")
const CharacterStatServiceScript = preload("res://systems/characters/character_stat_service.gd")
const StatCalculatorScript = preload("res://systems/stats/stat_calculator.gd")
const EquipmentDefinitionScript = preload("res://systems/equipment/equipment_definition.gd")
const EquipmentStateScript = preload("res://systems/equipment/equipment_state.gd")
const EquipmentAssignmentScript = preload("res://systems/equipment/equipment_assignment.gd")
const EquipmentServiceScript = preload("res://systems/equipment/equipment_service.gd")
const EquipmentStatServiceScript = preload("res://systems/equipment/equipment_stat_service.gd")
const EquipmentUpgradeServiceScript = preload("res://systems/equipment/equipment_upgrade_service.gd")
const ReturnStateScript = preload("res://systems/return/return_state.gd")
const ReturnServiceScript = preload("res://systems/return/return_service.gd")
const ShardInventoryScript = preload("res://systems/shards/shard_inventory.gd")
const ShardServiceScript = preload("res://systems/shards/shard_service.gd")
const ShardSocketServiceScript = preload("res://systems/shards/shard_socket_service.gd")
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
var stat_calculator
var equipment_stat_service
var equipment_service
var equipment_upgrade_service
var shard_service
var shard_socket_service
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
var tutorial_gacha_reward_claimed: bool = false
var tutorial_ten_pull_completed: bool = false
var _next_equipment_instance_index: int = 1

func _ready() -> void:
	var registry = get_node_or_null("/root/DataRegistry")
	var formula = StageFormulaScript.new()
	if registry != null:
		formula = registry.create_stage_formula()
	stage_progression = StageProgressionScript.new(formula)
	stage_progression.stage_changed.connect(_on_stage_changed)
	character_stat_service = CharacterStatServiceScript.new()
	stat_calculator = StatCalculatorScript.new()
	equipment_stat_service = EquipmentStatServiceScript.new()
	equipment_service = EquipmentServiceScript.new()
	equipment_upgrade_service = EquipmentUpgradeServiceScript.new()
	shard_service = ShardServiceScript.new()
	shard_socket_service = ShardSocketServiceScript.new()
	shard_inventory = ShardInventoryScript.new(shard_service.inventory_cap())
	return_state = ReturnStateScript.new()
	return_state.snacks = 0
	return_state.parts = 0
	return_state.shard_upgrade_material = 0
	return_state.stones = 0
	return_service = ReturnServiceScript.new()
	gacha_service = GachaServiceScript.new()
	gacha_inventory = GachaInventoryScript.new()
	save_service = SaveServiceScript.new()
	offline_service = OfflineServiceScript.new()
	character_gacha_pool = GachaPoolScript.default_character_pool()
	equipment_gacha_pool = GachaPoolScript.default_equipment_pool()
	equipment_assignment = EquipmentAssignmentScript.new()
	_create_debug_characters()
	team_state = TeamStateScript.new(["char_shiromaru"])
	_create_debug_equipment()
	_create_debug_shards()
	gacha_inventory.owned_characters["char_shiromaru"] = true
	gacha_inventory.character_duplicate_tokens["char_shiromaru"] = 0
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

func claim_tutorial_gacha_reward() -> Dictionary:
	if tutorial_gacha_reward_claimed:
		return {"success": false, "reason": "already_claimed"}
	tutorial_gacha_reward_claimed = true
	return_state.stones += 500
	return {"success": true, "stones": 500}

func create_save_data() -> Dictionary:
	var save_data = save_service.create_save(
		stage_progression,
		return_state,
		debug_character_states,
		debug_equipment_states,
		equipment_assignment,
		gacha_inventory,
		shard_inventory,
		team_state
	)
	save_data["tutorial_gacha_reward_claimed"] = tutorial_gacha_reward_claimed
	save_data["tutorial_ten_pull_completed"] = tutorial_ten_pull_completed
	save_data["next_equipment_instance_index"] = _next_equipment_instance_index
	return save_data

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
	tutorial_gacha_reward_claimed = bool(save_data.get("tutorial_gacha_reward_claimed", tutorial_gacha_reward_claimed))
	tutorial_ten_pull_completed = bool(save_data.get("tutorial_ten_pull_completed", tutorial_ten_pull_completed))
	_next_equipment_instance_index = max(1, int(save_data.get("next_equipment_instance_index", _next_equipment_instance_index)))
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
	var result = equipment_service.equip_to_character(character_id, equipment_id, _debug_character_definitions_by_id(), debug_equipment_states, equipment_assignment)
	if not bool(result.get("success", false)):
		return result
	combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return result

func unequip_item(character_id: String) -> Dictionary:
	var result = equipment_service.unequip_from_character(character_id, _debug_character_definitions_by_id(), equipment_assignment)
	if bool(result.get("success", false)):
		combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return result

func set_equipment_shard(equipment_id: String, socket_index: int, shard_id: String) -> Dictionary:
	var result = {}
	if shard_id == "":
		result = shard_socket_service.detach_shard(debug_equipment_states, equipment_id, socket_index)
	else:
		result = shard_socket_service.socket_shard(debug_equipment_states, shard_inventory, equipment_id, socket_index, shard_id)
	if bool(result.get("success", false)):
		combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return result

func move_equipment_shard(equipment_id: String, socket_index: int, shard_id: String) -> Dictionary:
	var result = shard_socket_service.move_shard(debug_equipment_states, shard_inventory, equipment_id, socket_index, shard_id)
	if bool(result.get("success", false)):
		combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
	return result

func socket_stat_delta(equipment_id: String, socket_index: int, shard_id: String) -> Dictionary:
	if not debug_equipment_states.has(equipment_id):
		return {"success": false, "reason": "unknown_equipment"}
	var definition_id = debug_equipment_states[equipment_id].definition_id
	if not debug_equipment_definitions.has(definition_id):
		return {"success": false, "reason": "unknown_equipment_definition"}
	return stat_calculator.socket_stat_delta(debug_equipment_definitions[definition_id], debug_equipment_states[equipment_id], shard_inventory, socket_index, shard_id)

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
	_apply_gacha_results_to_owned_state(pool.category, results)
	if pool.category == GachaPoolScript.CATEGORY_CHARACTER and count == 10:
		tutorial_ten_pull_completed = true
	return {
		"success": true,
		"cost": cost,
		"results": results
	}

func _apply_gacha_results_to_owned_state(category: String, results: Array) -> void:
	if category == GachaPoolScript.CATEGORY_CHARACTER:
		var states_by_id = _debug_character_states_by_id()
		for result in results:
			var character_id = str(result.get("item_id", ""))
			if character_id == "":
				continue
			if not states_by_id.has(character_id):
				debug_character_states.append(CharacterStateScript.new(character_id, 1, 0))
				states_by_id[character_id] = debug_character_states[debug_character_states.size() - 1]
		_fill_empty_team_slots()
		combat_session = CombatSessionScript.new(stage_progression, _create_debug_party())
		return

	if category == GachaPoolScript.CATEGORY_EQUIPMENT:
		for result in results:
			var definition_id = str(result.get("item_id", ""))
			if definition_id == "":
				continue
			if not debug_equipment_definitions.has(definition_id):
				continue
			var instance_id = _next_equipment_instance_id(definition_id)
			debug_equipment_states[instance_id] = EquipmentStateScript.new(instance_id, 1, definition_id)

func _next_equipment_instance_id(definition_id: String) -> String:
	var instance_id = "%s_inst_%03d" % [definition_id, _next_equipment_instance_index]
	_next_equipment_instance_index += 1
	while debug_equipment_states.has(instance_id):
		instance_id = "%s_inst_%03d" % [definition_id, _next_equipment_instance_index]
		_next_equipment_instance_index += 1
	return instance_id

func _fill_empty_team_slots() -> void:
	var owned_ids = []
	for state in debug_character_states:
		owned_ids.append(state.character_id)
	for slot in range(0, 3):
		var members = team_state.team_members(slot)
		for index in range(0, members.size()):
			if str(members[index]) != "":
				continue
			if index < owned_ids.size():
				members[index] = owned_ids[index]
		team_state.set_team_members(slot, members)

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
		var equipment_id = equipment_assignment.equipped_equipment_id(definition.character_id)
		if equipment_id != "" and debug_equipment_states.has(equipment_id):
			var equipment_state = debug_equipment_states[equipment_id]
			var definition_id = equipment_state.definition_id
			if debug_equipment_definitions.has(definition_id):
				party.append(stat_calculator.combat_state(definition, state, debug_equipment_definitions[definition_id], equipment_state, shard_inventory, milestone_damage_percent()))
				continue
		party.append(stat_calculator.combat_state(definition, state, null, null, null, milestone_damage_percent()))
	return party

func _create_debug_characters() -> void:
	debug_character_definitions = [
		CharacterDefinitionScript.new("char_pote", "SSR", "fire", "pure_dps", 1.0, "ぽて", 10.0, 100000.0, 0.08, 0.5, 0.2, "passive_journey_beginning"),
		CharacterDefinitionScript.new("char_meteor", "SSR", "fire", "crit", 0.8, "メテオ", 12.5, 125000.0, 0.12, 0.7, 0.2, "passive_falling_star"),
		CharacterDefinitionScript.new("char_nemurin", "SR", "water", "reaction", 1.0, "ねむりん", 6.5, 65000.0, 0.08, 0.5, 0.2, "passive_drowsy_rain"),
		CharacterDefinitionScript.new("char_ururu", "SR", "grass", "speed", 1.25, "うるる", 5.2, 52000.0, 0.05, 0.5, 0.2, "passive_sprout_rhythm"),
		CharacterDefinitionScript.new("char_kuromo", "R", "grass", "reaction", 0.92, "くろも", 3.8, 38000.0, 0.05, 0.5, 0.3, "passive_clinging_spores"),
		CharacterDefinitionScript.new("char_nobiru", "R", "none", "pure_dps", 1.2, "のびる", 3.5, 35000.0, 0.08, 0.5, 0.0, "passive_endless_reach"),
		CharacterDefinitionScript.new("char_hakonya", "R", "fire", "support", 0.9, "はこにゃ", 4.7, 47000.0, 0.06, 0.6, 0.2, "passive_packed_power"),
		CharacterDefinitionScript.new("char_mofuri", "R", "water", "reaction", 1.05, "もふり", 3.6, 36000.0, 0.05, 0.5, 0.3, "passive_bursting_drop"),
		CharacterDefinitionScript.new("char_kokemaru", "N", "grass", "pure_dps", 1.2, "こけまる", 2.5, 25000.0, 0.05, 0.5, 0.2, "passive_take_root"),
		CharacterDefinitionScript.new("char_shiromaru", "N", "none", "pure_dps", 1.0, "しろまる", 3.0, 30000.0, 0.05, 0.5, 0.0, "passive_straight_strike"),
		CharacterDefinitionScript.new("char_pyon", "N", "fire", "speed", 1.3, "ぴょん", 2.3, 23000.0, 0.07, 0.5, 0.2, "passive_hasty_spark"),
		CharacterDefinitionScript.new("char_zun", "N", "none", "pure_dps", 0.78, "ずん", 3.8, 38000.0, 0.05, 0.5, 0.0, "passive_stored_strength")
	]
	debug_character_states = [
		CharacterStateScript.new("char_shiromaru", 1, 0)
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
		"equip_stardrop_spear": EquipmentDefinitionScript.new("equip_stardrop_spear", "SSR", "attack", "星しずくの槍", 0.12, 12.0, "weapon_speed_20", {"attack_speed_percent": 0.2}),
		"equip_twilight_grimoire": EquipmentDefinitionScript.new("equip_twilight_grimoire", "SSR", "attack", "宵書のしるべ", 0.12, 12.0, "weapon_element_25", {"element_damage_percent": 0.25}),
		"equip_sky_spear": EquipmentDefinitionScript.new("equip_sky_spear", "SR", "attack", "空色の小槍", 0.1, 10.0, "weapon_crit_rate_8", {"critical_rate": 0.08}),
		"equip_young_wind_bow": EquipmentDefinitionScript.new("equip_young_wind_bow", "SR", "attack", "若風の弓", 0.1, 10.0, "weapon_speed_15", {"attack_speed_percent": 0.15}),
		"equip_blue_dew_ring": EquipmentDefinitionScript.new("equip_blue_dew_ring", "SR", "attack", "青露のゆびわ", 0.1, 10.0, "weapon_crit_damage_25", {"critical_damage": 0.25}),
		"equip_windwait_feather": EquipmentDefinitionScript.new("equip_windwait_feather", "R", "attack", "風待ちの羽根", 0.075, 7.5, "weapon_speed_12", {"attack_speed_percent": 0.12}),
		"equip_morning_dew_crown": EquipmentDefinitionScript.new("equip_morning_dew_crown", "R", "attack", "朝露のかんむり", 0.075, 7.5, "weapon_crit_rate_7", {"critical_rate": 0.07}),
		"equip_traveler_bag": EquipmentDefinitionScript.new("equip_traveler_bag", "R", "attack", "旅人のかばん", 0.075, 7.5, "weapon_upgrade_discount_10", {"level_cost_discount": 0.1}),
		"equip_fourleaf_charm": EquipmentDefinitionScript.new("equip_fourleaf_charm", "N", "attack", "四つ葉のおまもり", 0.055, 5.5, "weapon_crit_rate_4", {"critical_rate": 0.04}),
		"equip_forest_mushroom": EquipmentDefinitionScript.new("equip_forest_mushroom", "N", "attack", "森のこのこ", 0.055, 5.5, "weapon_grass_damage_8", {"grass_damage_percent": 0.08}),
		"equip_lightdrop_bottle": EquipmentDefinitionScript.new("equip_lightdrop_bottle", "N", "attack", "ひかり雫のびん", 0.055, 5.5, "weapon_application_5", {"application_rate": 0.05}),
		"equip_spring_flower_charm": EquipmentDefinitionScript.new("equip_spring_flower_charm", "N", "attack", "はる花のおまもり", 0.055, 5.5, "weapon_reaction_10", {"reaction_damage_percent": 0.1})
	}
	debug_equipment_states = {}

func _create_debug_shards() -> void:
	pass

func _equipment_modifiers_for_character(character_id: String) -> Dictionary:
	var equipment_id = equipment_assignment.equipped_equipment_id(character_id)
	if equipment_id == "":
		return {}
	if not debug_equipment_states.has(equipment_id):
		return {}
	var equipment_state = debug_equipment_states[equipment_id]
	var definition_id = equipment_state.definition_id
	if not debug_equipment_definitions.has(definition_id):
		return {}
	var modifiers = stat_calculator.equipment_modifiers(debug_equipment_definitions[definition_id], equipment_state, shard_inventory)
	modifiers["milestone_damage_percent"] = milestone_damage_percent()
	return modifiers

func combat_state_for_character(character_id: String):
	var definitions = _debug_character_definitions_by_id()
	var states = _debug_character_states_by_id()
	if not definitions.has(character_id) or not states.has(character_id):
		return null
	var equipment_id = equipment_assignment.equipped_equipment_id(character_id)
	if equipment_id != "" and debug_equipment_states.has(equipment_id):
		var equipment_state = debug_equipment_states[equipment_id]
		var definition_id = equipment_state.definition_id
		if debug_equipment_definitions.has(definition_id):
			return stat_calculator.combat_state(definitions[character_id], states[character_id], debug_equipment_definitions[definition_id], equipment_state, shard_inventory, milestone_damage_percent())
	return stat_calculator.combat_state(definitions[character_id], states[character_id], null, null, null, milestone_damage_percent())

func equipment_attack_percent(equipment_id: String) -> float:
	if not debug_equipment_states.has(equipment_id):
		return 0.0
	var equipment_state = debug_equipment_states[equipment_id]
	var definition_id = equipment_state.definition_id
	if not debug_equipment_definitions.has(definition_id):
		return 0.0
	var modifiers = stat_calculator.equipment_modifiers(debug_equipment_definitions[definition_id], equipment_state, null)
	return float(modifiers.get(EquipmentDefinitionScript.STAT_ATTACK_PERCENT, 0.0))

func equipment_definition_for_instance(equipment_id: String):
	if debug_equipment_definitions.has(equipment_id):
		return debug_equipment_definitions[equipment_id]
	if not debug_equipment_states.has(equipment_id):
		return null
	var definition_id = debug_equipment_states[equipment_id].definition_id
	return debug_equipment_definitions.get(definition_id, null)
