class_name EquipmentStatService
extends RefCounted

const EquipmentDefinitionScript = preload("res://systems/equipment/equipment_definition.gd")

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

func attack_percent(definition, state) -> float:
	if definition.equipment_type != EquipmentDefinitionScript.TYPE_ATTACK:
		return 0.0

	var rarity_table = ATTACK_PERCENT_BY_RARITY_LEVEL.get(definition.rarity, {})
	if not rarity_table.has(state.level):
		push_error("Equipment attack percent is unresolved for rarity %s level %d" % [definition.rarity, state.level])
		return 0.0
	return float(rarity_table[state.level])

func stat_modifiers(definition, state) -> Dictionary:
	return {
		EquipmentDefinitionScript.STAT_ATTACK_PERCENT: attack_percent(definition, state)
	}

func combined_stat_modifiers(definition, state, shard_modifiers: Dictionary = {}) -> Dictionary:
	var modifiers = stat_modifiers(definition, state)
	for stat_id in shard_modifiers.keys():
		modifiers[stat_id] = float(modifiers.get(stat_id, 0.0)) + float(shard_modifiers[stat_id])
	return modifiers

func is_attack_percent_defined(definition, level: int) -> bool:
	var rarity_table = ATTACK_PERCENT_BY_RARITY_LEVEL.get(definition.rarity, {})
	return rarity_table.has(level)
