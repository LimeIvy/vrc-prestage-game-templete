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

func _init(id: String, character_rarity: String, character_element: String, character_archetype: String = ARCHETYPE_PURE_DPS, attack_speed: float = 1.0, character_display_name: String = "") -> void:
	character_id = id
	rarity = character_rarity
	element = character_element
	archetype = character_archetype
	base_attack_speed = max(attack_speed, 0.0)
	display_name = character_display_name
	if display_name == "":
		display_name = id
