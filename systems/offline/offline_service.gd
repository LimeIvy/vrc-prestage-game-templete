class_name OfflineService
extends RefCounted

const SECONDS_PER_HOUR = 3600.0
const SHARDS_PER_HOUR = 8.3333333333

func preview_rewards(elapsed_seconds: float, current_stage: int) -> Dictionary:
	var seconds = max(elapsed_seconds, 0.0)
	var stage_factor = max(current_stage, 1)
	var hours = seconds / SECONDS_PER_HOUR
	return {
		"elapsed_seconds": seconds,
		"snacks": int(floor(hours * _snacks_per_hour(stage_factor))),
		"parts": int(floor(hours * _parts_per_hour(stage_factor))),
		"shard_acquisition_budget": hours * SHARDS_PER_HOUR,
		"stones": 0,
		"stage_advance": 0
	}

func apply_offline(return_state, elapsed_seconds: float, current_stage: int) -> Dictionary:
	var rewards = preview_rewards(elapsed_seconds, current_stage)
	return_state.snacks += int(rewards["snacks"])
	return_state.parts += int(rewards["parts"])
	return_state.shard_acquisition_budget += float(rewards["shard_acquisition_budget"])
	return rewards

func apply_from_save_time(return_state, save_data: Dictionary, now_unix_time: float, current_stage: int) -> Dictionary:
	var last_active = float(save_data.get("last_active_time", now_unix_time))
	return apply_offline(return_state, max(now_unix_time - last_active, 0.0), current_stage)

func _snacks_per_hour(current_stage: int) -> float:
	return 10.0 + float(current_stage)

func _parts_per_hour(current_stage: int) -> float:
	return 8.0 + float(current_stage) * 0.8
