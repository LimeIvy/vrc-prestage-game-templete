class_name EquipmentStatService
extends RefCounted

const EquipmentDefinitionScript = preload("res://systems/equipment/equipment_definition.gd")
const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")

const ATTACK_PERCENT_BY_RARITY_LEVEL = {
	"N": {
		1: 0.2,
		5: 0.5,
		10: 1.0,
		15: 1.8,
		20: 2.8,
		25: 4.0,
		30: 5.5
	},
	"R": {
		1: 0.3,
		5: 0.75,
		10: 1.5,
		15: 2.7,
		20: 4.2,
		25: 6.0,
		30: 7.5
	},
	"SR": {
		1: 0.45,
		5: 1.1,
		10: 2.2,
		15: 4.0,
		20: 6.2,
		25: 8.5,
		30: 10.0
	},
	"SSR": {
		1: 0.6,
		5: 1.5,
		10: 3.0,
		15: 5.5,
		20: 8.0,
		25: 10.5,
		30: 12.0
	}
}

var _equipment_balance: Dictionary = {}

func _init(balance_data: Dictionary = {}) -> void:
	if balance_data.is_empty():
		balance_data = StageFormulaScript.load_balance_data()
	_equipment_balance = balance_data.get("equipment", {})

func attack_percent(definition, state) -> float:
	if definition.equipment_type != EquipmentDefinitionScript.TYPE_ATTACK:
		return 0.0
	if definition.attack_percent_lv1 > 0.0 and definition.attack_percent_lv30 > 0.0:
		return _scaled_level_value(definition.attack_percent_lv1, definition.attack_percent_lv30, state.level)

	var data_attack_percent = _data_attack_percent(definition.rarity, state.level)
	if data_attack_percent >= 0.0:
		return data_attack_percent

	var rarity_table = ATTACK_PERCENT_BY_RARITY_LEVEL.get(definition.rarity, {})
	if not rarity_table.has(state.level):
		push_error("Equipment attack percent is unresolved for rarity %s level %d" % [definition.rarity, state.level])
		return 0.0
	return float(rarity_table[state.level])

func stat_modifiers(definition, state) -> Dictionary:
	var modifiers = definition.unique_modifiers.duplicate(true)
	modifiers[EquipmentDefinitionScript.STAT_ATTACK_PERCENT] = float(modifiers.get(EquipmentDefinitionScript.STAT_ATTACK_PERCENT, 0.0)) + attack_percent(definition, state)
	return modifiers

func combined_stat_modifiers(definition, state, shard_modifiers: Dictionary = {}) -> Dictionary:
	var modifiers = stat_modifiers(definition, state)
	for stat_id in shard_modifiers.keys():
		modifiers[stat_id] = float(modifiers.get(stat_id, 0.0)) + float(shard_modifiers[stat_id])
	return modifiers

func is_attack_percent_defined(definition, level: int) -> bool:
	if _data_attack_percent(definition.rarity, level) >= 0.0:
		return true
	var rarity_table = ATTACK_PERCENT_BY_RARITY_LEVEL.get(definition.rarity, {})
	return rarity_table.has(level)

func _data_attack_percent(rarity: String, level: int) -> float:
	var attack_tables = _equipment_balance.get("attack_percent_by_rarity_level", {})
	if typeof(attack_tables) != TYPE_DICTIONARY:
		return -1.0
	var rarity_table = attack_tables.get(rarity, {})
	if typeof(rarity_table) != TYPE_DICTIONARY:
		return -1.0
	var level_key = str(level)
	if not rarity_table.has(level_key):
		return -1.0
	return float(rarity_table[level_key])

func _scaled_level_value(level_one: float, level_thirty: float, level: int) -> float:
	var clamped_level = clamp(level, 1, 30)
	if clamped_level <= 1:
		return level_one
	if clamped_level >= 30:
		return level_thirty
	var exponent = float(clamped_level - 1) / 29.0
	return level_one * pow(level_thirty / level_one, exponent)
