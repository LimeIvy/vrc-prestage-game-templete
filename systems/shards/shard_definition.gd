class_name ShardDefinition
extends RefCounted

const RARITY_SSR = "SSR"

const STAT_ATTACK_PERCENT = "attack_percent"
const STAT_CRIT_RATE = "crit_rate"
const STAT_CRIT_DAMAGE = "crit_damage"
const STAT_ATTACK_SPEED_PERCENT = "attack_speed_percent"
const STAT_ELEMENT_DAMAGE_PERCENT = "element_damage_percent"

const STAT_POOL = [
	STAT_ATTACK_PERCENT,
	STAT_CRIT_RATE,
	STAT_CRIT_DAMAGE,
	STAT_ATTACK_SPEED_PERCENT,
	STAT_ELEMENT_DAMAGE_PERCENT
]

const SSR_MAIN_RANGES = {
	STAT_ATTACK_PERCENT: {"min": 3.0, "max": 3.75},
	STAT_CRIT_RATE: {"min": 0.10, "max": 0.125},
	STAT_CRIT_DAMAGE: {"min": 0.50, "max": 0.75},
	STAT_ATTACK_SPEED_PERCENT: {"min": 0.20, "max": 0.25},
	STAT_ELEMENT_DAMAGE_PERCENT: {"min": 0.40, "max": 0.60}
}

const SSR_SUB_RANGES = {
	STAT_ATTACK_PERCENT: {"min": 1.0, "max": 1.5},
	STAT_CRIT_RATE: {"min": 0.05, "max": 0.07},
	STAT_CRIT_DAMAGE: {"min": 0.20, "max": 0.30},
	STAT_ATTACK_SPEED_PERCENT: {"min": 0.08, "max": 0.12},
	STAT_ELEMENT_DAMAGE_PERCENT: {"min": 0.15, "max": 0.25}
}

static func range_for(rarity: String, stat_id: String, is_main: bool) -> Dictionary:
	if rarity != RARITY_SSR:
		push_error("Shard roll range is unresolved for rarity %s" % rarity)
		return {}
	var ranges = SSR_SUB_RANGES
	if is_main:
		ranges = SSR_MAIN_RANGES
	return ranges.get(stat_id, {})
