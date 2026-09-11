class_name ReturnService
extends RefCounted

const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")

const REPEATABLE_REWARDS = {
	100: {"snacks": 200, "parts": 160},
	200: {"snacks": 280, "parts": 220},
	300: {"snacks": 390, "parts": 310},
	400: {"snacks": 550, "parts": 440},
	500: {"snacks": 770, "parts": 620},
	600: {"snacks": 1080, "parts": 860},
	700: {"snacks": 1510, "parts": 1210},
	800: {"snacks": 2110, "parts": 1690},
	900: {"snacks": 2950, "parts": 2360},
	1000: {"snacks": 4130, "parts": 3300},
	1100: {"snacks": 4870, "parts": 3900},
	1200: {"snacks": 5750, "parts": 4600},
	1300: {"snacks": 6780, "parts": 5420},
	1400: {"snacks": 8000, "parts": 6400},
	1500: {"snacks": 9440, "parts": 7550},
	1600: {"snacks": 11140, "parts": 8910},
	1700: {"snacks": 13150, "parts": 10520},
	1800: {"snacks": 15510, "parts": 12410},
	1900: {"snacks": 18300, "parts": 14640},
	2000: {"snacks": 21630, "parts": 17300},
	2100: {"snacks": 24870, "parts": 19900},
	2200: {"snacks": 28600, "parts": 22880},
	2300: {"snacks": 32890, "parts": 26310},
	2400: {"snacks": 37820, "parts": 30260},
	2500: {"snacks": 43500, "parts": 34800},
	2600: {"snacks": 50020, "parts": 40020},
	2700: {"snacks": 57520, "parts": 46020},
	2800: {"snacks": 66150, "parts": 52920},
	2900: {"snacks": 76070, "parts": 60860},
	3000: {"snacks": 87490, "parts": 69990},
	3100: {"snacks": 94490, "parts": 75590},
	3200: {"snacks": 102050, "parts": 81640},
	3300: {"snacks": 110210, "parts": 88170},
	3400: {"snacks": 119030, "parts": 95220},
	3500: {"snacks": 128550, "parts": 102840},
	3600: {"snacks": 138840, "parts": 111070},
	3700: {"snacks": 149950, "parts": 119960},
	3800: {"snacks": 161940, "parts": 129550},
	3900: {"snacks": 174900, "parts": 139920},
	4000: {"snacks": 188890, "parts": 151110},
	4100: {"snacks": 204000, "parts": 163200},
	4200: {"snacks": 220320, "parts": 176260},
	4300: {"snacks": 237950, "parts": 190360},
	4400: {"snacks": 256980, "parts": 205580},
	4500: {"snacks": 277540, "parts": 222030},
	4600: {"snacks": 299740, "parts": 239790},
	4700: {"snacks": 323720, "parts": 258980},
	4800: {"snacks": 349620, "parts": 279700},
	4900: {"snacks": 377590, "parts": 302070},
	5000: {"snacks": 407810, "parts": 326250}
}

var _return_balance: Dictionary = {}

func _init(balance_data: Dictionary = {}) -> void:
	if balance_data.is_empty():
		balance_data = StageFormulaScript.load_balance_data()
	_return_balance = balance_data.get("return", {})

func required_return_stage(return_state) -> int:
	var step = int(_return_balance.get("step", 100))
	var cap = int(_return_balance.get("requirement_cap", 5000))
	return min((return_state.return_count + 1) * step, cap)

func can_return(return_state, highest_stage_in_run: int) -> bool:
	return highest_stage_in_run >= required_return_stage(return_state)

func milestone_damage_percent(return_state) -> float:
	var milestone_bonus = _return_balance.get("milestone_damage_bonus", {})
	return float(milestone_bonus.get("value", 0.05)) * float(return_state.milestone_count())

func perform_return(return_state, stage_progression) -> Dictionary:
	var highest_stage = stage_progression.highest_stage_in_run
	if not can_return(return_state, highest_stage):
		return {"success": false, "reason": "requirement_not_met"}

	var reward_stage = _reward_stage_for(highest_stage)
	var repeatable = REPEATABLE_REWARDS.get(reward_stage, {"snacks": 0, "parts": 0})
	var snacks_reward = int(repeatable["snacks"])
	var parts_reward = int(repeatable["parts"])
	var stones_reward = 0
	var claimed_return_stages: Array = []
	var claimed_milestones: Array = []

	var capped_highest = min(highest_stage, int(_return_balance.get("requirement_cap", 5000)))
	var step = int(_return_balance.get("step", 100))
	for stage in range(step, capped_highest + 1, step):
		if not return_state.has_claimed_return_stage(stage):
			return_state.claim_return_stage(stage)
			claimed_return_stages.append(stage)
			stones_reward += 50

	var milestone_step = int(_return_balance.get("milestone_step", 500))
	for stage in range(milestone_step, capped_highest + 1, milestone_step):
		if not return_state.has_claimed_milestone(stage):
			return_state.claim_milestone(stage)
			claimed_milestones.append(stage)
			stones_reward += 500
			snacks_reward += int(repeatable["snacks"]) * 2
			parts_reward += int(repeatable["parts"]) * 2

	return_state.return_count += 1
	return_state.snacks += snacks_reward
	return_state.parts += parts_reward
	return_state.stones += stones_reward
	stage_progression.reset_run()

	return {
		"success": true,
		"highest_stage": highest_stage,
		"reward_stage": reward_stage,
		"snacks": snacks_reward,
		"parts": parts_reward,
		"stones": stones_reward,
		"claimed_return_stages": claimed_return_stages,
		"claimed_milestones": claimed_milestones
	}

func _reward_stage_for(highest_stage: int) -> int:
	var capped = min(highest_stage, int(_return_balance.get("requirement_cap", 5000)))
	var rounded = int(floor(float(capped) / 100.0)) * 100
	return max(100, rounded)
