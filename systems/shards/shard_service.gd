class_name ShardService
extends RefCounted

const ShardDefinitionScript = preload("res://systems/shards/shard_definition.gd")
const ShardStateScript = preload("res://systems/shards/shard_state.gd")
const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")

var _shard_balance: Dictionary = {}
var _rng = RandomNumberGenerator.new()

func _init(balance_data: Dictionary = {}) -> void:
	if balance_data.is_empty():
		balance_data = StageFormulaScript.load_balance_data()
	_shard_balance = balance_data.get("shard", {})

func set_seed(seed: int) -> void:
	_rng.seed = seed

func inventory_cap() -> int:
	var cap = _shard_balance.get("inventory_cap", {})
	return int(cap.get("value", 200))

func upgrade_cost(target_level: int) -> int:
	var costs = _shard_balance.get("upgrade_cost", {})
	return int(costs.get(str(target_level), 0))

func growth_tiers() -> Array:
	return _shard_balance.get("growth_tiers_of_initial", [])

func create_shard(shard_id: String, rarity: String, main_stat: String, sub_stat: String, main_roll = null, sub_roll = null):
	if main_stat == sub_stat:
		push_error("Shard main stat and sub stat must differ: %s" % shard_id)
		return null

	var main_value = _roll_value(rarity, main_stat, true, main_roll)
	var sub_value = _roll_value(rarity, sub_stat, false, sub_roll)
	return ShardStateScript.new(shard_id, rarity, main_stat, sub_stat, main_value, sub_value)

func upgrade_shard(shard, main_tier = null, sub_tier = null) -> Dictionary:
	if not shard.can_upgrade():
		return {
			"success": false,
			"cost": 0,
			"level_before": shard.level,
			"level_after": shard.level
		}

	var target_level = shard.level + 1
	var selected_main_tier = _select_growth_tier(main_tier)
	var selected_sub_tier = _select_growth_tier(sub_tier)
	var cost = upgrade_cost(target_level)
	var before = shard.level
	shard.apply_growth(selected_main_tier, selected_sub_tier)
	return {
		"success": true,
		"cost": cost,
		"level_before": before,
		"level_after": shard.level,
		"main_tier": selected_main_tier,
		"sub_tier": selected_sub_tier
	}

func equipped_modifiers(equipment_state, inventory) -> Dictionary:
	var modifiers = {}
	for shard_id in equipment_state.shard_socket_ids:
		if shard_id == "":
			continue
		var shard = inventory.get_shard(shard_id)
		if shard == null:
			continue
		var shard_modifiers = shard.stat_modifiers()
		for stat_id in shard_modifiers.keys():
			modifiers[stat_id] = float(modifiers.get(stat_id, 0.0)) + float(shard_modifiers[stat_id])
	return modifiers

func _roll_value(rarity: String, stat_id: String, is_main: bool, forced_roll) -> float:
	var value_range = ShardDefinitionScript.range_for(rarity, stat_id, is_main)
	if value_range.is_empty():
		return 0.0
	if forced_roll != null:
		return clamp(float(forced_roll), float(value_range["min"]), float(value_range["max"]))
	return _rng.randf_range(float(value_range["min"]), float(value_range["max"]))

func _select_growth_tier(forced_tier) -> float:
	var tiers = growth_tiers()
	if tiers.is_empty():
		return 0.0
	if forced_tier != null:
		if not tiers.has(float(forced_tier)):
			push_error("Shard growth tier is not configured: %s" % str(forced_tier))
			return float(tiers[0])
		return float(forced_tier)
	var index = _rng.randi_range(0, tiers.size() - 1)
	return float(tiers[index])
