class_name EquipmentUpgradeService
extends RefCounted

const EquipmentStateScript = preload("res://systems/equipment/equipment_state.gd")
const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")

const GATE_LEVELS = [5, 10, 15, 20, 25, 30]

const NORMAL_BAND_COSTS = {
	1: 50,
	5: 150,
	10: 400,
	15: 1000,
	20: 2500,
	25: 6000
}

var _equipment_balance: Dictionary = {}
var _rng = RandomNumberGenerator.new()

func _init(balance_data: Dictionary = {}) -> void:
	if balance_data.is_empty():
		balance_data = StageFormulaScript.load_balance_data()
	_equipment_balance = balance_data.get("equipment", {})

func set_seed(seed: int) -> void:
	_rng.seed = seed

func is_gate_level(level: int) -> bool:
	return GATE_LEVELS.has(level)

func gate_success_chance(level: int) -> float:
	var gate_success = _equipment_balance.get("gate_success", {})
	return float(gate_success.get(str(level), 0.0))

func gate_attempt_cost(level: int) -> int:
	var gate_cost = _equipment_balance.get("gate_cost", {})
	return int(gate_cost.get(str(level), 0))

func normal_upgrade_cost(from_level: int) -> int:
	var band_start = _normal_band_start(from_level)
	return int(NORMAL_BAND_COSTS.get(band_start, 0))

func next_attempt_cost(state) -> int:
	if state.level >= EquipmentStateScript.MAX_LEVEL:
		return 0
	if is_gate_level(state.level):
		return gate_attempt_cost(state.level)
	return normal_upgrade_cost(state.level)

func attempt_upgrade(state, force_gate_success = null) -> Dictionary:
	if state.level >= EquipmentStateScript.MAX_LEVEL:
		return {
			"success": false,
			"cost": 0,
			"level_before": state.level,
			"level_after": state.level,
			"was_gate": false
		}

	var before = state.level
	var was_gate = is_gate_level(before)
	var cost = next_attempt_cost(state)
	var success = true

	if was_gate:
		if force_gate_success == null:
			success = _rng.randf() < gate_success_chance(before)
		else:
			success = bool(force_gate_success)

	if success:
		state.set_level(before + 1)

	return {
		"success": success,
		"cost": cost,
		"level_before": before,
		"level_after": state.level,
		"was_gate": was_gate
	}

func _normal_band_start(level: int) -> int:
	if level < 5:
		return 1
	if level < 10:
		return 5
	if level < 15:
		return 10
	if level < 20:
		return 15
	if level < 25:
		return 20
	return 25
