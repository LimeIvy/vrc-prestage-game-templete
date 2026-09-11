class_name ReturnState
extends RefCounted

var return_count: int = 0
var snacks: int = 0
var parts: int = 0
var shard_upgrade_material: int = 0
var shard_acquisition_budget: float = 0.0
var stones: int = 0
var claimed_return_stages: Dictionary = {}
var claimed_milestones: Dictionary = {}

func has_claimed_return_stage(stage: int) -> bool:
	return claimed_return_stages.has(stage)

func claim_return_stage(stage: int) -> void:
	claimed_return_stages[stage] = true

func has_claimed_milestone(stage: int) -> bool:
	return claimed_milestones.has(stage)

func claim_milestone(stage: int) -> void:
	claimed_milestones[stage] = true

func milestone_count() -> int:
	return claimed_milestones.size()
