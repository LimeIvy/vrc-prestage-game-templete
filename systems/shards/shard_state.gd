class_name ShardState
extends RefCounted

const MIN_LEVEL = 1
const MAX_LEVEL = 5

var shard_id: String
var rarity: String
var main_stat: String
var sub_stat: String
var initial_main_value: float
var initial_sub_value: float
var current_main_value: float
var current_sub_value: float
var level: int = MIN_LEVEL
var growth_history: Array = []

func _init(id: String, shard_rarity: String, shard_main_stat: String, shard_sub_stat: String, main_value: float, sub_value: float) -> void:
	shard_id = id
	rarity = shard_rarity
	main_stat = shard_main_stat
	sub_stat = shard_sub_stat
	initial_main_value = main_value
	initial_sub_value = sub_value
	current_main_value = main_value
	current_sub_value = sub_value
	if main_stat == sub_stat:
		push_error("Shard main stat and sub stat must differ: %s" % shard_id)

func can_upgrade() -> bool:
	return level < MAX_LEVEL

func apply_growth(main_tier: float, sub_tier: float) -> void:
	if not can_upgrade():
		return
	current_main_value += initial_main_value * main_tier
	current_sub_value += initial_sub_value * sub_tier
	level += 1
	growth_history.append({"main": main_tier, "sub": sub_tier})

func stat_modifiers() -> Dictionary:
	var modifiers = {}
	modifiers[main_stat] = float(modifiers.get(main_stat, 0.0)) + current_main_value
	modifiers[sub_stat] = float(modifiers.get(sub_stat, 0.0)) + current_sub_value
	return modifiers
