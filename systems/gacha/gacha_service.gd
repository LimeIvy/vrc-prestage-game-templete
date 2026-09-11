class_name GachaService
extends RefCounted

const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")
const GachaPoolScript = preload("res://systems/gacha/gacha_pool.gd")

var _gacha_balance: Dictionary = {}
var _rng = RandomNumberGenerator.new()

func _init(balance_data: Dictionary = {}) -> void:
	if balance_data.is_empty():
		balance_data = StageFormulaScript.load_balance_data()
	_gacha_balance = balance_data.get("gacha", {})

func set_seed(seed: int) -> void:
	_rng.seed = seed

func cost_for_pulls(count: int) -> int:
	if count == 10:
		return int(_gacha_balance.get("cost_ten", 500))
	return int(_gacha_balance.get("cost_single", 50)) * count

func pull_one(pool) -> Dictionary:
	var rarity = _roll_rarity(false)
	return _result_for_rarity(pool, rarity, false)

func pull_ten(pool) -> Array:
	var results: Array = []
	var has_sr_plus = false
	for index in range(0, 10):
		var rarity = _roll_rarity(false)
		if _is_sr_plus(rarity):
			has_sr_plus = true
		results.append(_result_for_rarity(pool, rarity, false))

	if bool(_gacha_balance.get("ten_pull_sr_plus_guarantee", true)) and not has_sr_plus:
		results[9] = _result_for_rarity(pool, _roll_rarity(true), true)
	return results

func apply_results(inventory, results: Array) -> void:
	for result in results:
		inventory.add_result(result)

func _roll_rarity(sr_plus_only: bool) -> String:
	var rates = _gacha_balance.get("rates", {})
	var roll = _rng.randf()
	var order = ["N", "R", "SR", "SSR"]
	if sr_plus_only:
		order = ["SR", "SSR"]
		var sr = float(rates.get("SR", 0.10))
		var ssr = float(rates.get("SSR", 0.01))
		var total = sr + ssr
		if total <= 0.0:
			return "SR"
		if roll < ssr / total:
			return "SSR"
		return "SR"

	var cumulative = 0.0
	for rarity in order:
		cumulative += float(rates.get(rarity, 0.0))
		if roll < cumulative:
			return rarity
	return "N"

func _result_for_rarity(pool, rarity: String, guaranteed: bool) -> Dictionary:
	var entries = pool.entries_for_rarity(rarity)
	if entries.is_empty():
		push_error("Gacha pool has no entries for rarity %s" % rarity)
		return {
			"category": pool.category,
			"rarity": rarity,
			"item_id": "",
			"guaranteed": guaranteed
		}

	var index = _rng.randi_range(0, entries.size() - 1)
	return {
		"category": pool.category,
		"rarity": rarity,
		"item_id": str(entries[index]),
		"guaranteed": guaranteed
	}

func _is_sr_plus(rarity: String) -> bool:
	return rarity == "SR" or rarity == "SSR"
