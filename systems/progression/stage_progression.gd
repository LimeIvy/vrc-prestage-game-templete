class_name StageProgression
extends RefCounted

const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")

signal stage_changed(stage: int)
signal enemy_spawned(stage: int, enemy_type: String, hp: float)

const ENEMY_TYPE_NORMAL = "normal"
const ENEMY_TYPE_BOSS = "boss"

var current_stage: int = 1
var highest_stage_in_run: int = 1
var current_enemy_hp: float = 0.0
var current_enemy_type: String = ENEMY_TYPE_NORMAL
var auto_boss_retry_enabled: bool = true
var formula
var _boss_farm_locked: bool = false

func _init(stage_formula = null) -> void:
	formula = StageFormulaScript.new()
	if stage_formula != null:
		formula = stage_formula
	start_new_save()

func start_new_save() -> void:
	highest_stage_in_run = 1
	set_stage(1)

func set_stage(stage: int) -> void:
	current_stage = max(stage, 1)
	highest_stage_in_run = max(highest_stage_in_run, current_stage)
	_spawn_enemy_for_current_stage()
	stage_changed.emit(current_stage)

func reset_run() -> void:
	highest_stage_in_run = 1
	_boss_farm_locked = false
	set_stage(1)

func defeat_current_enemy() -> void:
	if is_current_enemy_boss():
		_boss_farm_locked = false
		set_stage(current_stage + 1)
		return

	if _boss_farm_locked:
		set_stage(current_stage)
		return

	set_stage(current_stage + 1)

func defeat_normal_enemy() -> void:
	defeat_current_enemy()

func fail_boss() -> void:
	if not is_current_enemy_boss():
		return

	_boss_farm_locked = not auto_boss_retry_enabled
	set_stage(current_stage - 1)

func required_dps() -> float:
	return formula.required_dps(current_stage)

func is_current_enemy_boss() -> bool:
	return current_enemy_type == ENEMY_TYPE_BOSS

func is_boss_stage(stage: int) -> bool:
	return stage > 0 and stage % 50 == 0

func _spawn_enemy_for_current_stage() -> void:
	if is_boss_stage(current_stage):
		current_enemy_type = ENEMY_TYPE_BOSS
		current_enemy_hp = formula.boss_hp(current_stage)
	else:
		current_enemy_type = ENEMY_TYPE_NORMAL
		current_enemy_hp = formula.normal_enemy_hp(current_stage)
	enemy_spawned.emit(current_stage, current_enemy_type, current_enemy_hp)
