class_name EquipmentDefinition
extends RefCounted

const STAT_ATTACK_PERCENT = "attack_percent"
const TYPE_ATTACK = "attack"

var equipment_id: String
var rarity: String
var equipment_type: String

func _init(id: String, equipment_rarity: String, type: String = TYPE_ATTACK) -> void:
	equipment_id = id
	rarity = equipment_rarity
	equipment_type = type
