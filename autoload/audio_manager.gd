extends Node

const SETTINGS_PATH = "user://audio_settings.json"
const BGM_BUS = "BGM"
const SE_BUS = "SE"

var bgm_volume: float = 0.7
var se_volume: float = 0.8
var _bgm_player: AudioStreamPlayer

func _ready() -> void:
	_ensure_bus(BGM_BUS)
	_ensure_bus(SE_BUS)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BGM_BUS
	add_child(_bgm_player)
	_load_settings()
	_apply_volumes()

func set_bgm_volume(value: float) -> void:
	bgm_volume = clamp(value, 0.0, 1.0)
	_apply_bus_volume(BGM_BUS, bgm_volume)
	_save_settings()

func set_se_volume(value: float) -> void:
	se_volume = clamp(value, 0.0, 1.0)
	_apply_bus_volume(SE_BUS, se_volume)
	_save_settings()

func play_bgm(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	_bgm_player.stream = stream
	_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player != null:
		_bgm_player.stop()

func play_se(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	var player = AudioStreamPlayer.new()
	player.bus = SE_BUS
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)

func _apply_volumes() -> void:
	_apply_bus_volume(BGM_BUS, bgm_volume)
	_apply_bus_volume(SE_BUS, se_volume)

func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var index = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, volume <= 0.0)
	var safe_volume = max(volume, 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(safe_volume))

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	bgm_volume = clamp(float(parsed.get("bgm_volume", bgm_volume)), 0.0, 1.0)
	se_volume = clamp(float(parsed.get("se_volume", se_volume)), 0.0, 1.0)

func _save_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"bgm_volume": bgm_volume,
		"se_volume": se_volume
	}))
