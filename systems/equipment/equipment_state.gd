class_name EquipmentState
extends RefCounted

const MIN_LEVEL = 1
const MAX_LEVEL = 30
const SHARD_SOCKET_COUNT = 3

var equipment_id: String
var definition_id: String
var level: int = MIN_LEVEL
var shard_socket_ids: Array = []

func _init(id: String, initial_level: int = MIN_LEVEL, source_definition_id: String = "") -> void:
	equipment_id = id
	definition_id = source_definition_id
	if definition_id == "":
		definition_id = id
	set_level(initial_level)
	shard_socket_ids = ["", "", ""]

func set_level(value: int) -> void:
	level = clamp(value, MIN_LEVEL, MAX_LEVEL)

func set_shard_socket(index: int, shard_id: String) -> void:
	if index < 0 or index >= SHARD_SOCKET_COUNT:
		push_error("Shard socket index out of range: %d" % index)
		return
	shard_socket_ids[index] = shard_id
