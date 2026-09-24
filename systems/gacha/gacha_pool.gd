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
		"N": ["char_kokemaru", "char_shiromaru", "char_pyon", "char_zun"],
		"R": ["char_kuromo", "char_nobiru", "char_hakonya", "char_mofuri"],
		"SR": ["char_nemurin", "char_ururu"],
		"SSR": ["char_pote", "char_meteor"]
	})

static func default_equipment_pool():
	return GachaPool.new(CATEGORY_EQUIPMENT, {
		"N": ["equip_fourleaf_charm", "equip_forest_mushroom", "equip_lightdrop_bottle", "equip_spring_flower_charm"],
		"R": ["equip_windwait_feather", "equip_morning_dew_crown", "equip_traveler_bag"],
		"SR": ["equip_sky_spear", "equip_young_wind_bow", "equip_blue_dew_ring"],
		"SSR": ["equip_stardrop_spear", "equip_twilight_grimoire"]
	})
