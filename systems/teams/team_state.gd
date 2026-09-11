class_name TeamState
extends RefCounted

const TEAM_SLOT_COUNT = 3
const TEAM_MEMBER_COUNT = 4

var selected_team_slot: int = 0
var teams: Array = []

func _init(default_member_ids: Array = []) -> void:
	teams = []
	for _slot in range(0, TEAM_SLOT_COUNT):
		teams.append(_normalized_members(default_member_ids))

func select_slot(slot_index: int) -> void:
	selected_team_slot = clamp(slot_index, 0, TEAM_SLOT_COUNT - 1)

func current_members() -> Array:
	return team_members(selected_team_slot)

func team_members(slot_index: int) -> Array:
	var safe_index = clamp(slot_index, 0, TEAM_SLOT_COUNT - 1)
	return teams[safe_index].duplicate(true)

func set_team_members(slot_index: int, member_ids: Array) -> void:
	var safe_index = clamp(slot_index, 0, TEAM_SLOT_COUNT - 1)
	teams[safe_index] = _normalized_members(member_ids)

func set_member(slot_index: int, member_index: int, character_id: String) -> void:
	if member_index < 0 or member_index >= TEAM_MEMBER_COUNT:
		push_error("Team member index out of range: %d" % member_index)
		return
	var safe_index = clamp(slot_index, 0, TEAM_SLOT_COUNT - 1)
	teams[safe_index][member_index] = character_id

func _normalized_members(member_ids: Array) -> Array:
	var normalized: Array = []
	for index in range(0, TEAM_MEMBER_COUNT):
		if index < member_ids.size():
			normalized.append(str(member_ids[index]))
		else:
			normalized.append("")
	return normalized
