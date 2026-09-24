class_name ShardDefinition
extends RefCounted

const RARITY_SSR = "SSR"

const STAT_ATTACK_PERCENT = "attack_percent"
const STAT_CRITICAL_RATE = "critical_rate"
const STAT_CRITICAL_DAMAGE = "critical_damage"
const STAT_ATTACK_SPEED_PERCENT = "attack_speed_percent"
const STAT_ELEMENT_DAMAGE_PERCENT = "element_damage_percent"

const STAT_POOL = [
	STAT_ATTACK_PERCENT,
	STAT_CRITICAL_RATE,
	STAT_CRITICAL_DAMAGE,
	STAT_ATTACK_SPEED_PERCENT,
	STAT_ELEMENT_DAMAGE_PERCENT
]

const SSR_MAIN_BY_LEVEL = {
	STAT_ATTACK_PERCENT: [1.0, 2.0, 3.0, 4.0, 5.0],
	STAT_ATTACK_SPEED_PERCENT: [0.375, 0.75, 1.125, 1.5, 1.875],
	STAT_CRITICAL_RATE: [0.2, 0.4, 0.6, 0.8, 1.0],
	STAT_CRITICAL_DAMAGE: [0.6, 1.2, 1.8, 2.4, 3.0],
	STAT_ELEMENT_DAMAGE_PERCENT: [0.475, 0.95, 1.425, 1.9, 2.375]
}

const SSR_SUB_BY_LEVEL = {
	STAT_ATTACK_PERCENT: [0.4, 0.8, 1.2, 1.6, 2.0],
	STAT_ATTACK_SPEED_PERCENT: [0.3, 0.6, 0.9, 1.2, 1.5],
	STAT_CRITICAL_RATE: [0.16, 0.32, 0.48, 0.64, 0.8],
	STAT_CRITICAL_DAMAGE: [0.48, 0.96, 1.44, 1.92, 2.4],
	STAT_ELEMENT_DAMAGE_PERCENT: [0.38, 0.76, 1.14, 1.52, 1.9]
}

const RARITY_MULTIPLIER = {
	"SSR": 1.0,
	"SR": 0.8,
	"R": 0.6,
	"N": 0.45
}

static func range_for(rarity: String, stat_id: String, is_main: bool) -> Dictionary:
	var value = value_for(rarity, stat_id, is_main, 1)
	if value < 0.0:
		return {}
	return {"min": value, "max": value}

static func value_for(rarity: String, stat_id: String, is_main: bool, level: int) -> float:
	if not RARITY_MULTIPLIER.has(rarity):
		push_error("Shard rarity is unknown: %s" % rarity)
		return -1.0
	var table = SSR_SUB_BY_LEVEL
	if is_main:
		table = SSR_MAIN_BY_LEVEL
	if not table.has(stat_id):
		push_error("Shard stat id is unknown: %s" % stat_id)
		return -1.0
	var index = clamp(level, 1, 5) - 1
	return float(table[stat_id][index]) * float(RARITY_MULTIPLIER[rarity])
