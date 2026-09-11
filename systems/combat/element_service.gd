class_name ElementService
extends RefCounted

const ELEMENT_FIRE = "fire"
const ELEMENT_GRASS = "grass"
const ELEMENT_WATER = "water"
const ELEMENT_NONE = "none"

const REACTION_BURN = "burn"
const REACTION_EXTRA_DAMAGE = "extra_damage"
const REACTION_SPEED_BUFF = "speed_buff"

const ADVANTAGE_MULTIPLIER = 1.2
const DISADVANTAGE_MULTIPLIER = 0.8
const NEUTRAL_MULTIPLIER = 1.0

func damage_multiplier(attacker_element: String, target_element: String) -> float:
	if attacker_element == ELEMENT_NONE or target_element == ELEMENT_NONE:
		return NEUTRAL_MULTIPLIER
	if _advantage_target(attacker_element) == target_element:
		return ADVANTAGE_MULTIPLIER
	if _advantage_target(target_element) == attacker_element:
		return DISADVANTAGE_MULTIPLIER
	return NEUTRAL_MULTIPLIER

func can_apply(element: String) -> bool:
	return element != ELEMENT_NONE

func reaction_for(first_element: String, second_element: String) -> String:
	if first_element == second_element:
		return ""
	if _has_pair(first_element, second_element, ELEMENT_FIRE, ELEMENT_GRASS):
		return REACTION_BURN
	if _has_pair(first_element, second_element, ELEMENT_FIRE, ELEMENT_WATER):
		return REACTION_EXTRA_DAMAGE
	if _has_pair(first_element, second_element, ELEMENT_WATER, ELEMENT_GRASS):
		return REACTION_SPEED_BUFF
	return ""

func _advantage_target(element: String) -> String:
	if element == ELEMENT_FIRE:
		return ELEMENT_GRASS
	if element == ELEMENT_GRASS:
		return ELEMENT_WATER
	if element == ELEMENT_WATER:
		return ELEMENT_FIRE
	return ELEMENT_NONE

func _has_pair(first_element: String, second_element: String, pair_a: String, pair_b: String) -> bool:
	return (first_element == pair_a and second_element == pair_b) or (first_element == pair_b and second_element == pair_a)
