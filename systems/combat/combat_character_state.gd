class_name CombatCharacterState
extends RefCounted

var character_id: String
var final_attack: float
var final_attack_speed: float
var element: String
var application_rate: float
var final_critical_rate: float
var final_critical_damage_bonus: float
var final_element_damage_percent: float
var attack_timer: float = 0.0

func _init(id: String, attack: float, attack_speed: float, character_element: String = "none", app_rate: float = 0.2, critical_rate: float = 0.0, critical_damage_bonus: float = 0.5, element_damage_percent: float = 0.0) -> void:
	character_id = id
	final_attack = max(attack, 0.0)
	final_attack_speed = max(attack_speed, 0.0)
	element = character_element
	application_rate = clamp(app_rate, 0.0, 1.0)
	final_critical_rate = clamp(critical_rate, 0.0, 1.0)
	final_critical_damage_bonus = max(critical_damage_bonus, 0.0)
	final_element_damage_percent = max(element_damage_percent, 0.0)

func attack_interval() -> float:
	if final_attack_speed <= 0.0:
		return INF
	return 1.0 / final_attack_speed

func reset_timer() -> void:
	attack_timer = attack_interval()
