class_name CombatSession
extends RefCounted

const ElementServiceScript = preload("res://systems/combat/element_service.gd")

signal enemy_damaged(stage: int, remaining_hp: float, damage: float)
signal stage_cleared(stage: int)
signal boss_failed(stage: int)
signal enemy_spawned(stage: int, hp: float)

var stage_progression
var party: Array = []
var boss_time_remaining: float = 0.0
var enemy_element: String = "none"
var application_duration: float = 5.0
var speed_buff_time_remaining: float = 0.0
var speed_buff_multiplier: float = 1.0
var applications: Dictionary = {}
var reactions: Dictionary = {}
var element_service = ElementServiceScript.new()
var _rng = RandomNumberGenerator.new()

func _init(progression, selected_party: Array) -> void:
	stage_progression = progression
	party = selected_party.duplicate()
	for character in party:
		character.reset_timer()
	_reset_boss_timer()
	enemy_spawned.emit(stage_progression.current_stage, stage_progression.current_enemy_hp)

func tick(delta: float) -> void:
	if delta <= 0.0:
		return

	if _tick_boss_timer(delta):
		return

	_tick_element_timers(delta)
	if _tick_reactions(delta):
		return

	for character in party:
		var cleared_stage = _tick_character(character, delta)
		if cleared_stage:
			_reset_party_timers()
			_reset_boss_timer()
			return

func _tick_character(character, delta: float) -> bool:
	if character.final_attack_speed <= 0.0:
		return false

	character.attack_timer -= delta
	while character.attack_timer <= 0.0:
		var cleared_stage = _apply_character_attack(character)
		character.attack_timer += _attack_interval(character)
		if cleared_stage:
			return true
	return false

func set_seed(seed: int) -> void:
	_rng.seed = seed

func set_enemy_element(element: String) -> void:
	enemy_element = element

func force_application(character) -> bool:
	return _apply_element_application(character)

func _apply_character_attack(character) -> bool:
	var multiplier = element_service.damage_multiplier(character.element, enemy_element)
	var cleared_stage = _apply_damage(character.final_attack * multiplier)
	if cleared_stage:
		return true

	if element_service.can_apply(character.element) and _rng.randf() < character.application_rate:
		return _apply_element_application(character)
	return false

func _apply_attack(damage: float) -> bool:
	return _apply_damage(damage)

func _apply_damage(damage: float) -> bool:
	if stage_progression.current_enemy_hp <= 0.0:
		return false

	stage_progression.current_enemy_hp = max(stage_progression.current_enemy_hp - damage, 0.0)
	enemy_damaged.emit(stage_progression.current_stage, stage_progression.current_enemy_hp, damage)

	if stage_progression.current_enemy_hp <= 0.0:
		var cleared_stage = stage_progression.current_stage
		stage_cleared.emit(cleared_stage)
		stage_progression.defeat_current_enemy()
		enemy_spawned.emit(stage_progression.current_stage, stage_progression.current_enemy_hp)
		_clear_enemy_status()
		return true
	return false

func _reset_party_timers() -> void:
	for character in party:
		character.reset_timer()

func _attack_interval(character) -> float:
	if character.final_attack_speed <= 0.0:
		return INF
	return 1.0 / (character.final_attack_speed * speed_buff_multiplier)

func _reset_boss_timer() -> void:
	if stage_progression.is_current_enemy_boss():
		boss_time_remaining = stage_progression.formula.boss_time_limit_seconds()
	else:
		boss_time_remaining = 0.0

func _tick_boss_timer(delta: float) -> bool:
	if not stage_progression.is_current_enemy_boss():
		return false

	boss_time_remaining -= delta
	if boss_time_remaining > 0.0:
		return false

	var failed_stage = stage_progression.current_stage
	boss_failed.emit(failed_stage)
	stage_progression.fail_boss()
	_clear_enemy_status()
	_reset_party_timers()
	_reset_boss_timer()
	enemy_spawned.emit(stage_progression.current_stage, stage_progression.current_enemy_hp)
	return true

func _apply_element_application(character) -> bool:
	if not element_service.can_apply(character.element):
		return false

	for existing_element in applications.keys():
		if existing_element == character.element:
			var application = applications[existing_element]
			application["time_remaining"] = application_duration
			applications[existing_element] = application
			return false

		var reaction = element_service.reaction_for(existing_element, character.element)
		if reaction != "":
			applications.erase(existing_element)
			return _trigger_reaction(reaction, character)

	applications[character.element] = {
		"time_remaining": application_duration,
		"reactor_attack": character.final_attack
	}
	return false

func _trigger_reaction(reaction: String, reactor) -> bool:
	if reaction == ElementServiceScript.REACTION_EXTRA_DAMAGE:
		return _apply_damage(reactor.final_attack * 0.5)
	if reaction == ElementServiceScript.REACTION_SPEED_BUFF:
		speed_buff_time_remaining = 5.0
		speed_buff_multiplier = 1.2
		return false
	if reaction == ElementServiceScript.REACTION_BURN:
		reactions[reaction] = {
			"time_remaining": 4.0,
			"tick_remaining": 0.5,
			"tick_interval": 0.5,
			"reactor_attack": reactor.final_attack
		}
	return false

func _tick_element_timers(delta: float) -> void:
	for element in applications.keys():
		var application = applications[element]
		application["time_remaining"] = float(application["time_remaining"]) - delta
		if float(application["time_remaining"]) <= 0.0:
			applications.erase(element)
		else:
			applications[element] = application

	if speed_buff_time_remaining > 0.0:
		speed_buff_time_remaining -= delta
		if speed_buff_time_remaining <= 0.0:
			speed_buff_time_remaining = 0.0
			speed_buff_multiplier = 1.0

func _tick_reactions(delta: float) -> bool:
	if not reactions.has(ElementServiceScript.REACTION_BURN):
		return false

	var burn = reactions[ElementServiceScript.REACTION_BURN]
	burn["time_remaining"] = float(burn["time_remaining"]) - delta
	burn["tick_remaining"] = float(burn["tick_remaining"]) - delta
	while float(burn["tick_remaining"]) <= 0.0 and float(burn["time_remaining"]) >= 0.0:
		burn["tick_remaining"] = float(burn["tick_remaining"]) + float(burn["tick_interval"])
		if _apply_damage(float(burn["reactor_attack"]) * 0.075):
			return true
	if float(burn["time_remaining"]) <= 0.0:
		reactions.erase(ElementServiceScript.REACTION_BURN)
	else:
		reactions[ElementServiceScript.REACTION_BURN] = burn
	return false

func _clear_enemy_status() -> void:
	applications.clear()
	reactions.clear()
	speed_buff_time_remaining = 0.0
	speed_buff_multiplier = 1.0
