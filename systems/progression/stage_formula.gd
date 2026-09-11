class_name StageFormula
extends RefCounted

const BALANCE_PATH = "res://data/balance.json"

var _stage_curve: Dictionary

func _init(balance_data: Dictionary = {}) -> void:
	if balance_data.is_empty():
		balance_data = load_balance_data()
	_stage_curve = balance_data.get("stage_curve", {})

static func load_balance_data(path: String = BALANCE_PATH) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open balance data: %s" % path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Failed to parse balance data as Dictionary: %s" % path)
		return {}

	return parsed

func required_dps(stage: int) -> float:
	var safe_stage: int = max(stage, 1)
	for raw_segment in _stage_curve.get("segments", []):
		var segment: Dictionary = raw_segment
		var min_stage: int = int(segment.get("min", 1))
		var max_stage: int = int(segment.get("max", min_stage))
		if safe_stage >= min_stage and safe_stage <= max_stage:
			return _curve_value(
				safe_stage,
				int(segment.get("base_stage", min_stage)),
				float(segment.get("base_dps", 0.0)),
				float(segment.get("growth", 1.0))
			)

	var post_3000: Dictionary = _stage_curve.get("post_3000", {})
	var base_stage: int = int(post_3000.get("base_stage", 3000))
	var base_dps: float = float(post_3000.get("base_dps", 0.0))
	var doubles_every_stages: float = float(post_3000.get("doubles_every_stages", 1000.0))
	return base_dps * pow(2.0, float(safe_stage - base_stage) / doubles_every_stages)

func normal_enemy_hp(stage: int) -> float:
	return required_dps(stage) * normal_enemy_target_seconds()

func boss_hp(stage: int) -> float:
	return required_dps(stage) * boss_time_limit_seconds()

func normal_enemy_target_seconds() -> float:
	return float(_stage_curve.get("normal_enemy_target_seconds", 5.0))

func boss_time_limit_seconds() -> float:
	var boss_limit: Dictionary = _stage_curve.get("boss_time_limit_seconds", {})
	return float(boss_limit.get("value", 15.0))

func _curve_value(stage: int, base_stage: int, base_dps: float, growth: float) -> float:
	return base_dps * pow(growth, float(stage - base_stage))
