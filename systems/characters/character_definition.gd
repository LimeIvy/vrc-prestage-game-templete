class_name CharacterDefinition
extends RefCounted

const RARITY_N = "N"
const RARITY_R = "R"
const RARITY_SR = "SR"
const RARITY_SSR = "SSR"

const ARCHETYPE_PURE_DPS = "pure_dps"
const ARCHETYPE_CRIT = "crit"
const ARCHETYPE_SPEED = "speed"
const ARCHETYPE_REACTION = "reaction"
const ARCHETYPE_SUPPORT = "support"

var character_id: String
var rarity: String
var element: String
var archetype: String
var base_attack_speed: float
var display_name: String
var attack_lv1: float
var attack_lv30: float
var critical_rate: float
var critical_damage_bonus: float
var application_rate: float
var passive_id: String

func _init(id: String, character_rarity: String, character_element: String, character_archetype: String = ARCHETYPE_PURE_DPS, attack_speed: float = 1.0, character_display_name: String = "", base_attack_lv1: float = 0.0, base_attack_lv30: float = 0.0, base_critical_rate: float = 0.05, base_critical_damage_bonus: float = 0.5, base_application_rate: float = 0.2, character_passive_id: String = "") -> void:
	character_id = id
	rarity = character_rarity
	element = character_element
	archetype = character_archetype
	base_attack_speed = max(attack_speed, 0.0)
	display_name = character_display_name
	if display_name == "":
		display_name = id
	attack_lv1 = max(base_attack_lv1, 0.0)
	attack_lv30 = max(base_attack_lv30, 0.0)
	critical_rate = clamp(base_critical_rate, 0.0, 1.0)
	critical_damage_bonus = max(base_critical_damage_bonus, 0.0)
	application_rate = clamp(base_application_rate, 0.0, 1.0)
	passive_id = character_passive_id
