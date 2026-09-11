class_name CharacterState
extends RefCounted

const MIN_LEVEL = 1
const MAX_LEVEL = 30
const MIN_NAJIMI = 0
const MAX_NAJIMI = 3

var character_id: String
var level: int = MIN_LEVEL
var najimi: int = MIN_NAJIMI

func _init(id: String, initial_level: int = MIN_LEVEL, initial_najimi: int = MIN_NAJIMI) -> void:
	character_id = id
	set_level(initial_level)
	set_najimi(initial_najimi)

func set_level(value: int) -> void:
	level = clamp(value, MIN_LEVEL, MAX_LEVEL)

func set_najimi(value: int) -> void:
	najimi = clamp(value, MIN_NAJIMI, MAX_NAJIMI)
