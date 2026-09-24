class_name EquipmentDefinition
extends RefCounted

const STAT_ATTACK_PERCENT = "attack_percent"
const TYPE_ATTACK = "attack"

var equipment_id: String
var rarity: String
var equipment_type: String
var display_name: String
var attack_percent_lv1: float
var attack_percent_lv30: float
var unique_ability_id: String
var unique_modifiers: Dictionary

func _init(id: String, equipment_rarity: String, type: String = TYPE_ATTACK, equipment_display_name: String = "", attack_lv1: float = 0.0, attack_lv30: float = 0.0, ability_id: String = "", fixed_modifiers: Dictionary = {}) -> void:
	equipment_id = id
	rarity = equipment_rarity
	equipment_type = type
	display_name = equipment_display_name
	if display_name == "":
		display_name = id
	attack_percent_lv1 = max(attack_lv1, 0.0)
	attack_percent_lv30 = max(attack_lv30, 0.0)
	unique_ability_id = ability_id
	unique_modifiers = fixed_modifiers.duplicate(true)
