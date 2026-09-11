extends Node

const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")

var balance_data: Dictionary = {}

func _ready() -> void:
	reload()

func reload() -> void:
	balance_data = StageFormulaScript.load_balance_data()

func create_stage_formula():
	if balance_data.is_empty():
		reload()
	return StageFormulaScript.new(balance_data)
