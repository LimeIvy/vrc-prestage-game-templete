class_name GachaPool
extends RefCounted

const CATEGORY_CHARACTER = "character"
const CATEGORY_EQUIPMENT = "equipment"

var category: String
var entries_by_rarity: Dictionary = {}

func _init(pool_category: String, entries: Dictionary = {}) -> void:
	category = pool_category
	entries_by_rarity = entries

func entries_for_rarity(rarity: String) -> Array:
	return entries_by_rarity.get(rarity, [])

func has_rarity(rarity: String) -> bool:
	return entries_for_rarity(rarity).size() > 0

static func default_character_pool():
	return GachaPool.new(CATEGORY_CHARACTER, {
		"N": ["char_n_001", "char_n_002"],
		"R": ["char_r_001", "char_r_002"],
		"SR": ["char_sr_001", "char_sr_002"],
		"SSR": ["char_ssr_001", "char_ssr_002"]
	})

static func default_equipment_pool():
	return GachaPool.new(CATEGORY_EQUIPMENT, {
		"N": ["equip_n_001", "equip_n_002"],
		"R": ["equip_r_001", "equip_r_002"],
		"SR": ["equip_sr_001", "equip_sr_002"],
		"SSR": ["equip_ssr_001", "equip_ssr_002"]
	})
