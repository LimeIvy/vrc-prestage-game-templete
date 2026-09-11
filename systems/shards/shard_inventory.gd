class_name ShardInventory
extends RefCounted

var inventory_cap: int = 200
var shards: Dictionary = {}

func _init(cap: int = 200) -> void:
	inventory_cap = cap

func add_shard(shard) -> bool:
	if shards.size() >= inventory_cap:
		return false
	shards[shard.shard_id] = shard
	return true

func remove_shard(shard_id: String) -> void:
	shards.erase(shard_id)

func get_shard(shard_id: String):
	return shards.get(shard_id, null)

func has_shard(shard_id: String) -> bool:
	return shards.has(shard_id)

func count() -> int:
	return shards.size()
