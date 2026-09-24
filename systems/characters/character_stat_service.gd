class_name CharacterStatService
extends RefCounted

const CombatCharacterStateScript = preload("res://systems/combat/combat_character_state.gd")
const CharacterStateScript = preload("res://systems/characters/character_state.gd")
const EquipmentDefinitionScript = preload("res://systems/equipment/equipment_definition.gd")
const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")

const LEVEL_COSTS = [
	10,
	15,
	20,
	30,
	45,
	65,
	90,
	125,
	175,
	250,
	350,
	500,
	700,
	1000,
	1400,
	2000,
	2800,
	4000,
	5500,
	7500,
	10000,
	13500,
	18000,
	24000,
	32000,
	42000,
	55000,
	75000,
	100000
]

const PURE_DPS_BASE_ATTACK = {
	"N": {
		1: 4.0,
		5: 10.0,
		10: 36.0,
		15: 210.0,
		20: 1200.0,
		25: 8400.0,
		26: 10200.0,
		27: 12600.0,
		28: 16500.0,
		29: 21600.0,
		30: 30000.0
	},
	"R": {
		1: 5.0,
		5: 14.0,
		10: 50.0,
		15: 294.0,
		20: 1680.0,
		25: 11760.0,
		26: 14280.0,
		27: 17640.0,
		28: 23100.0,
		29: 30240.0,
		30: 42000.0
	},
	"SR": {
		1: 7.0,
		5: 20.0,
		10: 78.0,
		15: 455.0,
		20: 2600.0,
		25: 18200.0,
		26: 22100.0,
		27: 27300.0,
		28: 35750.0,
		29: 46800.0,
		30: 65000.0
	},
	"SSR": {
		1: 10.0,
		5: 30.0,
		10: 120.0,
		15: 700.0,
		20: 4000.0,
		25: 28000.0,
		26: 34000.0,
		27: 42000.0,
		28: 55000.0,
		29: 72000.0,
		30: 100000.0
	}
}

const ARCHETYPE_ATTACK_MODIFIERS = {
	"pure_dps": 1.0,
	"crit": 0.9,
	"speed": 0.8,
	"reaction": 0.75,
	"support": 0.7
}

var _character_balance: Dictionary = {}

func _init(balance_data: Dictionary = {}) -> void:
	if balance_data.is_empty():
		balance_data = StageFormulaScript.load_balance_data()
	_character_balance = balance_data.get("character", {})

func base_attack(definition, state) -> float:
	if definition.attack_lv1 > 0.0 and definition.attack_lv30 > 0.0:
		return _scaled_level_value(definition.attack_lv1, definition.attack_lv30, state.level)

	var data_base_attack = _data_base_attack(definition.rarity, state.level)
	if data_base_attack >= 0.0:
		var data_archetype_modifier = _data_archetype_modifier(definition.archetype)
		return data_base_attack * data_archetype_modifier

	var rarity_table = PURE_DPS_BASE_ATTACK.get(definition.rarity, {})
	if not rarity_table.has(state.level):
		push_error("Base attack is unresolved for rarity %s level %d" % [definition.rarity, state.level])
		return 0.0

	var archetype_modifier = ARCHETYPE_ATTACK_MODIFIERS.get(definition.archetype, 1.0)
	return float(rarity_table[state.level]) * float(archetype_modifier)

func final_attack(definition, state, equipment_modifiers: Dictionary = {}) -> float:
	var attack_percent = float(equipment_modifiers.get(EquipmentDefinitionScript.STAT_ATTACK_PERCENT, 0.0))
	var milestone_damage_percent = float(equipment_modifiers.get("milestone_damage_percent", 0.0))
	return base_attack(definition, state) * (1.0 + attack_percent) * (1.0 + milestone_damage_percent)

func combat_state(definition, state, equipment_modifiers: Dictionary = {}):
	var attack_speed_percent = float(equipment_modifiers.get("attack_speed_percent", 0.0))
	var application_rate_bonus = float(equipment_modifiers.get("application_rate", 0.0))
	var critical_rate_bonus = float(equipment_modifiers.get("critical_rate", 0.0))
	var critical_damage_bonus = float(equipment_modifiers.get("critical_damage", 0.0))
	var element_damage_percent = float(equipment_modifiers.get("element_damage_percent", 0.0))
	return CombatCharacterStateScript.new(
		definition.character_id,
		final_attack(definition, state, equipment_modifiers),
		definition.base_attack_speed * (1.0 + attack_speed_percent),
		definition.element,
		definition.application_rate + application_rate_bonus,
		definition.critical_rate + critical_rate_bonus,
		definition.critical_damage_bonus + critical_damage_bonus,
		element_damage_percent
	)

func level_up_cost(from_level: int) -> int:
	if from_level < CharacterStateScript.MIN_LEVEL or from_level >= CharacterStateScript.MAX_LEVEL:
		return 0
	var data_costs = _character_balance.get("level_costs", [])
	if typeof(data_costs) == TYPE_ARRAY and data_costs.size() >= from_level:
		return int(data_costs[from_level - 1])
	return int(LEVEL_COSTS[from_level - 1])

func cumulative_cost_to_level(level: int) -> int:
	var target_level = clamp(level, CharacterStateScript.MIN_LEVEL, CharacterStateScript.MAX_LEVEL)
	var total = 0
	for index in range(0, target_level - 1):
		total += int(LEVEL_COSTS[index])
	return total

func is_base_attack_defined(definition, level: int) -> bool:
	if _data_base_attack(definition.rarity, level) >= 0.0:
		return true
	var rarity_table = PURE_DPS_BASE_ATTACK.get(definition.rarity, {})
	return rarity_table.has(level)

func _data_base_attack(rarity: String, level: int) -> float:
	var base_attack_tables = _character_balance.get("pure_dps_base_attack", {})
	if typeof(base_attack_tables) != TYPE_DICTIONARY:
		return -1.0
	var rarity_table = base_attack_tables.get(rarity, {})
	if typeof(rarity_table) != TYPE_DICTIONARY:
		return -1.0
	var level_key = str(level)
	if not rarity_table.has(level_key):
		return -1.0
	return float(rarity_table[level_key])

func _data_archetype_modifier(archetype: String) -> float:
	var modifiers = _character_balance.get("archetype_attack_modifiers", {})
	if typeof(modifiers) == TYPE_DICTIONARY and modifiers.has(archetype):
		return float(modifiers[archetype])
	return float(ARCHETYPE_ATTACK_MODIFIERS.get(archetype, 1.0))

func _scaled_level_value(level_one: float, level_thirty: float, level: int) -> float:
	var clamped_level = clamp(level, CharacterStateScript.MIN_LEVEL, CharacterStateScript.MAX_LEVEL)
	if clamped_level <= CharacterStateScript.MIN_LEVEL:
		return level_one
	if clamped_level >= CharacterStateScript.MAX_LEVEL:
		return level_thirty
	var exponent = float(clamped_level - 1) / 29.0
	return round(level_one * pow(level_thirty / level_one, exponent))
