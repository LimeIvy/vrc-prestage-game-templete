class_name EnemyVisualGenerator
extends RefCounted

const DEFAULT_CATALOG_PATH = "res://data/enemy_visual_catalog.json"

var catalog: Dictionary = {}

func _init(catalog_path: String = DEFAULT_CATALOG_PATH) -> void:
	catalog = _load_catalog(catalog_path)

func recipe_for(stage: int, enemy_index: int = 0, version: int = 1) -> Dictionary:
	var seed = stable_seed(version, stage, enemy_index)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	var body = _pick(rng, catalog.get("bodies", []), {})
	var body_id = str(body.get("id", "round_01"))
	var pattern_id = _pick_allowed_id(rng, catalog.get("patterns", []), body.get("allowed_patterns", ["none"]), "none")
	var accessory_id = _pick_allowed_id(rng, catalog.get("accessories", []), body.get("allowed_accessories", ["none"]), "none")
	var eyes = _pick(rng, catalog.get("eyes", []), {"id": "dot_01"})
	var mouth = _pick(rng, catalog.get("mouths", []), {"id": "small_01"})
	var palette_count = max(_palette_count(), 1)

	return {
		"version": version,
		"seed": seed,
		"body": body_id,
		"body_palette": rng.randi_range(0, palette_count - 1),
		"eyes": str(eyes.get("id", "dot_01")),
		"mouth": str(mouth.get("id", "small_01")),
		"pattern": pattern_id,
		"pattern_palette": rng.randi_range(0, palette_count - 1),
		"accessory": accessory_id,
		"accessory_palette": rng.randi_range(0, palette_count - 1),
		"scale_x": _range(rng, 0.92, 1.10),
		"scale_y": _range(rng, 0.90, 1.08),
		"wobble_speed": _range(rng, 0.55, 1.25),
		"wobble_amount": _range(rng, 0.015, 0.055)
	}

func stable_seed(version: int, stage: int, enemy_index: int) -> int:
	return _fnv1a_31("enemy_visual_v%d:%d:%d" % [version, max(stage, 1), max(enemy_index, 0)])

func part_path(layer: String, part_id: String) -> String:
	var part = part_definition(layer, part_id)
	var file_path = str(part.get("file", ""))
	if file_path == "":
		return ""
	return "%s/%s" % [str(catalog.get("asset_root", "res://assets/enemies")), file_path]

func part_definition(layer: String, part_id: String) -> Dictionary:
	var key = "%ss" % layer
	if layer == "body":
		key = "bodies"
	elif layer == "accessory":
		key = "accessories"
	return _find_by_id(catalog.get(key, []), part_id)

func palette_color(palette_index: int, channel: String) -> Color:
	var palettes = catalog.get("palettes", [])
	if palettes.is_empty():
		return Color(1.0, 1.0, 1.0, 1.0)
	var index = abs(palette_index) % palettes.size()
	var palette = palettes[index]
	return Color.html(str(palette.get(channel, "#ffffff")))

func _load_catalog(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _pick(rng: RandomNumberGenerator, items, fallback: Dictionary) -> Dictionary:
	if typeof(items) != TYPE_ARRAY or items.is_empty():
		return fallback
	return items[rng.randi_range(0, items.size() - 1)]

func _pick_allowed_id(rng: RandomNumberGenerator, items, allowed, fallback_id: String) -> String:
	var candidates: Array = []
	if typeof(allowed) == TYPE_ARRAY:
		for item in items:
			var item_id = str(item.get("id", ""))
			if allowed.has(item_id):
				candidates.append(item_id)
	if candidates.is_empty():
		return fallback_id
	return str(candidates[rng.randi_range(0, candidates.size() - 1)])

func _find_by_id(items, item_id: String) -> Dictionary:
	if typeof(items) != TYPE_ARRAY:
		return {}
	for item in items:
		if str(item.get("id", "")) == item_id:
			return item
	return {}

func _palette_count() -> int:
	var palettes = catalog.get("palettes", [])
	if typeof(palettes) != TYPE_ARRAY:
		return 0
	return palettes.size()

func _range(rng: RandomNumberGenerator, min_value: float, max_value: float) -> float:
	return rng.randf_range(min_value, max_value)

func _fnv1a_31(text: String) -> int:
	var hash_value = 2166136261
	for index in range(0, text.length()):
		hash_value = hash_value ^ text.unicode_at(index)
		hash_value = int((hash_value * 16777619) % 2147483647)
	return max(hash_value, 1)
