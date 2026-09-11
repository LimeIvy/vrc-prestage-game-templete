class_name EquipmentDefinition
extends RefCounted

const STAT_ATTACK_PERCENT = "attack_percent"
const TYPE_ATTACK = "attack"

var equipment_id: String
var rarity: String
var equipment_type: String
var display_name: String

func _init(id: String, equipment_rarity: String, type: String = TYPE_ATTACK, equipment_display_name: String = "") -> void:
	equipment_id = id
	rarity = equipment_rarity
	equipment_type = type
	display_name = equipment_display_name
	if display_name == "":
		display_name = id
