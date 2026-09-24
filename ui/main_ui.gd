extends Control

const CharacterStateScript = preload("res://systems/characters/character_state.gd")
const EquipmentStateScript = preload("res://systems/equipment/equipment_state.gd")
const EnemyVisualGeneratorScript = preload("res://systems/enemies/enemy_visual_generator.gd")

const SAVE_PATH = "user://save.json"

var game_state
var current_tab: String = "battle"
var selected_character_index: int = 0
var selected_team_member_index: int = 0
var selected_equipment_id: String = ""
var selected_shard_id: String = "shard_inst_attack_critical"
var equipment_category: String = "equipment"
var character_right_tab: String = "najimi"
var team_right_tab: String = "status"
var gacha_category: String = "character"
var last_gacha_results: Array = []
var damage_popups: Array = []
var refresh_accumulator: float = 0.0
var settings_open: bool = false
var connected_combat_session
var enemy_visual_generator
var audio_manager

var resources_label: Label
var content_root: Control
var message_label: Label
var tab_buttons: Dictionary = {}

var panel_style: StyleBoxFlat
var dark_panel_style: StyleBoxFlat
var card_style: StyleBoxFlat
var selected_card_style: StyleBoxFlat
var accent_panel_style: StyleBoxFlat
var active_button_style: StyleBoxFlat
var button_style: StyleBoxFlat

func _ready() -> void:
	game_state = get_node("/root/GameState")
	audio_manager = get_node_or_null("/root/AudioManager")
	enemy_visual_generator = EnemyVisualGeneratorScript.new()
	_create_styles()
	_build_ui()
	_ensure_combat_signals()
	_set_tab("battle")

func _process(delta: float) -> void:
	_ensure_combat_signals()
	_refresh_top_bar()
	_tick_damage_popups(delta)
	refresh_accumulator += delta
	if current_tab == "battle" and refresh_accumulator >= 0.25:
		refresh_accumulator = 0.0
		_render_tab()

func _create_styles() -> void:
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.96, 0.99, 1.0, 0.88)
	panel_style.border_color = Color(0.62, 0.82, 1.0, 0.9)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16

	dark_panel_style = StyleBoxFlat.new()
	dark_panel_style.bg_color = Color(0.02, 0.12, 0.20, 0.72)
	dark_panel_style.border_color = Color(0.15, 0.55, 1.0, 0.45)
	dark_panel_style.set_border_width_all(1)
	dark_panel_style.set_corner_radius_all(10)
	dark_panel_style.content_margin_left = 18
	dark_panel_style.content_margin_right = 18
	dark_panel_style.content_margin_top = 12
	dark_panel_style.content_margin_bottom = 12

	card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(1.0, 1.0, 1.0, 0.82)
	card_style.border_color = Color(0.50, 0.70, 0.90, 0.75)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(10)
	card_style.content_margin_left = 12
	card_style.content_margin_right = 12
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 10

	selected_card_style = card_style.duplicate()
	selected_card_style.bg_color = Color(1.0, 0.96, 0.76, 0.92)
	selected_card_style.border_color = Color(1.0, 0.68, 0.18, 1.0)
	selected_card_style.set_border_width_all(3)

	accent_panel_style = StyleBoxFlat.new()
	accent_panel_style.bg_color = Color(0.10, 0.42, 0.78, 0.86)
	accent_panel_style.border_color = Color(0.78, 0.94, 1.0, 0.9)
	accent_panel_style.set_border_width_all(2)
	accent_panel_style.set_corner_radius_all(12)
	accent_panel_style.content_margin_left = 18
	accent_panel_style.content_margin_right = 18
	accent_panel_style.content_margin_top = 14
	accent_panel_style.content_margin_bottom = 14

	button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.93, 0.97, 1.0, 0.88)
	button_style.border_color = Color(0.40, 0.62, 0.82, 0.85)
	button_style.set_border_width_all(2)
	button_style.set_corner_radius_all(10)

	active_button_style = StyleBoxFlat.new()
	active_button_style.bg_color = Color(0.02, 0.47, 1.0, 0.95)
	active_button_style.border_color = Color(0.45, 0.92, 1.0, 1.0)
	active_button_style.set_border_width_all(3)
	active_button_style.set_corner_radius_all(10)

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background = ColorRect.new()
	background.color = Color(0.56, 0.78, 0.94, 1.0)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)

	var background_path = "res://assets/backgrounds/common/bg_skygarden_day.webp"
	if ResourceLoader.exists(background_path):
		var background_image = TextureRect.new()
		background_image.texture = load(background_path)
		background_image.anchor_right = 1.0
		background_image.anchor_bottom = 1.0
		background_image.stretch_mode = 6
		add_child(background_image)

	var field = ColorRect.new()
	field.color = Color(0.74, 0.88, 0.70, 0.65)
	field.anchor_top = 0.28
	field.anchor_right = 1.0
	field.anchor_bottom = 1.0
	add_child(field)

	var shade = ColorRect.new()
	shade.color = Color(0.02, 0.08, 0.12, 0.10)
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	add_child(shade)

	_add_background_decoration()

	var root = VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 38.0
	root.offset_top = 12.0
	root.offset_right = -38.0
	root.offset_bottom = -24.0
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	root.add_child(_build_top_bar())

	content_root = Control.new()
	content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content_root)

	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 24)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.add_theme_stylebox_override("normal", dark_panel_style)
	message_label.custom_minimum_size = Vector2(0, 54)
	root.add_child(message_label)

func _add_background_decoration() -> void:
	_add_decor_rect(Color(1.0, 1.0, 1.0, 0.22), Vector2(140, 120), Vector2(260, 58), 28)
	_add_decor_rect(Color(1.0, 1.0, 1.0, 0.18), Vector2(470, 88), Vector2(180, 42), 22)
	_add_decor_rect(Color(1.0, 1.0, 1.0, 0.20), Vector2(1320, 126), Vector2(310, 54), 28)
	_add_decor_rect(Color(0.38, 0.58, 0.50, 0.32), Vector2(104, 446), Vector2(270, 130), 18)
	_add_decor_rect(Color(0.30, 0.50, 0.42, 0.28), Vector2(1450, 430), Vector2(250, 145), 18)
	_add_decor_rect(Color(0.88, 0.94, 0.82, 0.38), Vector2(0, 760), Vector2(1920, 180), 0)

func _add_decor_rect(color: Color, position_value: Vector2, size_value: Vector2, radius: int) -> void:
	var panel = PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(color.r, color.g, color.b, 0.0)
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

func _build_top_bar() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 86)
	panel.add_theme_stylebox_override("panel", dark_panel_style)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	_add_nav_button(row, "X  戦闘", "battle")
	_add_nav_button(row, "●  なかま", "characters")
	_add_nav_button(row, "♟  ちーむ", "team")
	_add_nav_button(row, "□  もちもの", "equipment")
	_add_nav_button(row, "◎  であい", "gacha")
	_add_nav_button(row, "✥  きかん", "return")
	var settings_button = _button("設定", Vector2(110, 70))
	settings_button.pressed.connect(_on_settings_pressed)
	row.add_child(settings_button)

	resources_label = Label.new()
	resources_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	resources_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resources_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources_label.add_theme_font_size_override("font_size", 24)
	resources_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(resources_label)

	return panel

func _add_nav_button(parent: Control, label: String, tab_id: String) -> void:
	var button = _button(label, Vector2(168, 70))
	button.pressed.connect(_set_tab.bind(tab_id))
	parent.add_child(button)
	tab_buttons[tab_id] = button

func _button(label: String, min_size: Vector2 = Vector2(170, 64)) -> Button:
	var button = Button.new()
	button.text = label
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_focus_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_disabled_color", Color(0.12, 0.12, 0.12))
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_stylebox_override("hover", active_button_style)
	button.add_theme_stylebox_override("pressed", active_button_style)
	return button

func _set_tab(tab_id: String) -> void:
	current_tab = tab_id
	for key in tab_buttons.keys():
		var style = button_style
		if key == current_tab:
			style = active_button_style
		tab_buttons[key].add_theme_stylebox_override("normal", style)
	_render_tab()

func _clear_content() -> void:
	for child in content_root.get_children():
		child.queue_free()

func _render_tab() -> void:
	_clear_content()
	if current_tab == "battle":
		_render_battle()
	elif current_tab == "characters":
		_render_characters()
	elif current_tab == "team":
		_render_team()
	elif current_tab == "equipment":
		_render_equipment()
	elif current_tab == "gacha":
		_render_gacha()
	elif current_tab == "return":
		_render_return()
	_refresh_top_bar()
	if settings_open:
		_render_settings()

func _refresh_top_bar() -> void:
	if resources_label == null or game_state == null:
		return
	resources_label.text = "◇ ひかり石 %d    おやつ %d    パーツ %d" % [
		game_state.return_state.stones,
		game_state.return_state.snacks,
		game_state.return_state.parts
	]

func _render_battle() -> void:
	var root = VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 16)
	content_root.add_child(root)

	var arena = Control.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(arena)

	var stage_label = Label.new()
	stage_label.text = "STAGE %d" % game_state.current_stage()
	stage_label.position = Vector2(0, 26)
	stage_label.add_theme_font_size_override("font_size", 52)
	stage_label.add_theme_color_override("font_color", Color.WHITE)
	stage_label.add_theme_stylebox_override("normal", dark_panel_style)
	arena.add_child(stage_label)
	_render_tutorial_panel(arena)

	var enemy_box = VBoxContainer.new()
	enemy_box.anchor_left = 0.27
	enemy_box.anchor_right = 0.73
	enemy_box.offset_top = 28.0
	enemy_box.add_theme_constant_override("separation", 10)
	arena.add_child(enemy_box)

	var enemy_name = Label.new()
	enemy_name.text = _enemy_display_name()
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name.add_theme_font_size_override("font_size", 34)
	enemy_name.add_theme_color_override("font_color", Color(0.02, 0.08, 0.18))
	enemy_box.add_child(enemy_name)

	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 38)
	hp_bar.max_value = max(_current_enemy_max_hp(), 1.0)
	hp_bar.value = clamp(game_state.current_enemy_hp(), 0.0, hp_bar.max_value)
	enemy_box.add_child(hp_bar)

	var hp_label = Label.new()
	hp_label.text = "%s / %s" % [_format_number(game_state.current_enemy_hp()), _format_number(_current_enemy_max_hp())]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 30)
	enemy_box.add_child(hp_label)

	if game_state.current_enemy_type() == "boss":
		var timer_label = Label.new()
		timer_label.text = "残り %.1f 秒" % max(game_state.boss_time_remaining(), 0.0)
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.add_theme_font_size_override("font_size", 42)
		timer_label.add_theme_color_override("font_color", Color(0.86, 0.12, 0.10))
		enemy_box.add_child(timer_label)

	arena.add_child(_enemy_display())
	_render_damage_popups(arena)

	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 18)
	root.add_child(bottom)
	for character_id in game_state.team_state.current_members():
		var pair = _character_pair(character_id)
		if pair.is_empty():
			continue
		bottom.add_child(_character_card(pair["definition"], pair["state"], Vector2(220, 250), true))

	var auto_retry = CheckBox.new()
	auto_retry.text = "ボス失敗時 自動再挑戦"
	auto_retry.button_pressed = game_state.stage_progression.auto_boss_retry_enabled
	auto_retry.custom_minimum_size = Vector2(330, 76)
	auto_retry.add_theme_font_size_override("font_size", 26)
	auto_retry.add_theme_stylebox_override("normal", dark_panel_style)
	auto_retry.toggled.connect(_on_auto_retry_toggled)
	bottom.add_child(auto_retry)

func _render_tutorial_panel(arena: Control) -> void:
	if game_state.tutorial_ten_pull_completed:
		return
	var panel = _panel(Vector2(430, 0))
	panel.position = Vector2(0, 104)
	arena.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	if not game_state.tutorial_gacha_reward_claimed:
		box.add_child(_label("チュートリアル\nまずはしろまると戦ってみよう。\n次に10連でなかまを増やします。", 24))
		var reward = _button("ひかり石500を受け取る", Vector2(0, 64))
		reward.pressed.connect(_on_tutorial_reward_pressed)
		box.add_child(reward)
		return
	box.add_child(_label("ひかり石が集まりました。\nであいで10連して、なかまを増やしましょう。", 24))
	var gacha = _button("であいへ", Vector2(0, 64))
	gacha.pressed.connect(_on_tutorial_gacha_pressed)
	box.add_child(gacha)

func _enemy_display() -> Control:
	var holder = Control.new()
	holder.anchor_left = 0.36
	holder.anchor_right = 0.64
	holder.offset_top = 178.0
	holder.custom_minimum_size = Vector2(420, 300)

	if game_state.current_enemy_type() != "boss":
		return _generated_enemy_display(holder)

	var enemy_asset = _asset_image(_enemy_asset_path(), Vector2(360, 260), "")
	enemy_asset.position = Vector2(32, 24)
	holder.add_child(enemy_asset)
	return holder

func _generated_enemy_display(holder: Control) -> Control:
	var recipe = enemy_visual_generator.recipe_for(game_state.current_stage(), 0, 1)
	var elapsed = Time.get_ticks_msec() / 1000.0
	var wobble = sin(elapsed * float(recipe.get("wobble_speed", 1.0)) * TAU) * float(recipe.get("wobble_amount", 0.0)) * 80.0
	var root = Control.new()
	root.position = Vector2(32, 12 + wobble)
	root.custom_minimum_size = Vector2(360, 280)
	root.scale = Vector2(float(recipe.get("scale_x", 1.0)), float(recipe.get("scale_y", 1.0)))
	holder.add_child(root)

	var body_path = enemy_visual_generator.part_path("body", str(recipe.get("body", "")))
	if body_path != "" and ResourceLoader.exists(body_path):
		_add_enemy_layer(root, body_path, enemy_visual_generator.palette_color(int(recipe.get("body_palette", 0)), "body"), Vector2(300, 260), Vector2(30, 8))
		_add_enemy_layer(root, enemy_visual_generator.part_path("pattern", str(recipe.get("pattern", "none"))), enemy_visual_generator.palette_color(int(recipe.get("pattern_palette", 0)), "pattern"), Vector2(300, 260), Vector2(30, 8))
		_add_enemy_face_layers(root, recipe)
		_add_enemy_accessory_layer(root, recipe)
		return holder

	_add_generated_enemy_fallback(root, recipe)
	return holder

func _add_enemy_layer(parent: Control, path: String, tint: Color, size_value: Vector2, position_value: Vector2) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var layer = _asset_image(path, size_value, "")
	layer.size = size_value
	layer.position = position_value
	layer.modulate = tint
	parent.add_child(layer)

func _add_enemy_face_layers(parent: Control, recipe: Dictionary) -> void:
	var body = enemy_visual_generator.part_definition("body", str(recipe.get("body", "")))
	var eye = enemy_visual_generator.part_definition("eye", str(recipe.get("eyes", "")))
	var mouth = enemy_visual_generator.part_definition("mouth", str(recipe.get("mouth", "")))
	var face_anchor = _catalog_vector(body.get("face_anchor", {}), Vector2(180, 130))
	var eye_size = _catalog_size(eye.get("size", {}), Vector2(42, 42))
	var eye_spacing = float(body.get("eye_spacing", eye.get("eye_spacing", 90)))
	var eye_scale = float(eye.get("default_scale", 1.0))
	var scaled_eye_size = eye_size * eye_scale
	var eye_path = enemy_visual_generator.part_path("eye", str(recipe.get("eyes", "")))
	_add_enemy_layer(parent, eye_path, Color.WHITE, scaled_eye_size, face_anchor + Vector2(-eye_spacing * 0.5, 0.0) - scaled_eye_size * 0.5)
	_add_enemy_layer(parent, eye_path, Color.WHITE, scaled_eye_size, face_anchor + Vector2(eye_spacing * 0.5, 0.0) - scaled_eye_size * 0.5)
	var mouth_size = _catalog_size(mouth.get("size", {}), Vector2(52, 34))
	var mouth_offset = _catalog_vector(mouth.get("offset", {}), Vector2(0, 46))
	_add_enemy_layer(parent, enemy_visual_generator.part_path("mouth", str(recipe.get("mouth", ""))), Color.WHITE, mouth_size, face_anchor + mouth_offset - mouth_size * 0.5)

func _add_enemy_accessory_layer(parent: Control, recipe: Dictionary) -> void:
	var body = enemy_visual_generator.part_definition("body", str(recipe.get("body", "")))
	var head_anchor = _catalog_vector(body.get("head_anchor", {}), Vector2(180, 34))
	var accessory_path = enemy_visual_generator.part_path("accessory", str(recipe.get("accessory", "none")))
	var tint = enemy_visual_generator.palette_color(int(recipe.get("accessory_palette", 0)), "accessory")
	_add_enemy_layer(parent, accessory_path, tint, Vector2(120, 92), head_anchor - Vector2(60, 46))

func _add_generated_enemy_fallback(parent: Control, recipe: Dictionary) -> void:
	var shadow = _shape_panel(Color(0.04, 0.10, 0.12, 0.18), Vector2(78, 232), Vector2(270, 42), 24)
	parent.add_child(shadow)

	var body_color = enemy_visual_generator.palette_color(int(recipe.get("body_palette", 0)), "body")
	body_color.a = 0.96
	var body_id = str(recipe.get("body", "round_01"))
	var body_size = Vector2(300, 220)
	var body_pos = Vector2(56, 38)
	var radius = 94
	if body_id == "long_01":
		body_size = Vector2(248, 240)
		body_pos = Vector2(82, 24)
		radius = 70
	if body_id == "fluffy_01":
		body_size = Vector2(318, 210)
		body_pos = Vector2(48, 48)
		radius = 120
	var body = _shape_panel(body_color, body_pos, body_size, radius)
	parent.add_child(body)

	var shine = _shape_panel(Color(1.0, 1.0, 1.0, 0.20), Vector2(96, 62), Vector2(86, 42), 20)
	parent.add_child(shine)
	_add_fallback_pattern(parent, recipe)
	_add_fallback_accessory(parent, recipe)
	_add_fallback_face(parent, recipe)

func _add_fallback_face(parent: Control, recipe: Dictionary) -> void:
	var body = enemy_visual_generator.part_definition("body", str(recipe.get("body", "")))
	var eye = enemy_visual_generator.part_definition("eye", str(recipe.get("eyes", "")))
	var mouth = enemy_visual_generator.part_definition("mouth", str(recipe.get("mouth", "")))
	var face_anchor = _catalog_vector(body.get("face_anchor", {}), Vector2(180, 130))
	var eye_spacing = float(body.get("eye_spacing", eye.get("eye_spacing", 90)))
	var eye_text = _fallback_single_eye_text(str(recipe.get("eyes", "")))
	parent.add_child(_face_label(eye_text, face_anchor + Vector2(-eye_spacing * 0.5 - 12.0, -28.0), 46, Color(0.02, 0.09, 0.11)))
	parent.add_child(_face_label(eye_text, face_anchor + Vector2(eye_spacing * 0.5 - 12.0, -28.0), 46, Color(0.02, 0.09, 0.11)))
	var mouth_offset = _catalog_vector(mouth.get("offset", {}), Vector2(0, 46))
	parent.add_child(_face_label(_fallback_mouth_text(str(recipe.get("mouth", ""))), face_anchor + mouth_offset + Vector2(-18.0, -20.0), 34, Color(0.02, 0.09, 0.11)))

func _add_fallback_pattern(parent: Control, recipe: Dictionary) -> void:
	var pattern_id = str(recipe.get("pattern", "none"))
	if pattern_id == "none":
		return
	var pattern_color = enemy_visual_generator.palette_color(int(recipe.get("pattern_palette", 0)), "pattern")
	pattern_color.a = 0.34
	if pattern_id == "spots_01":
		parent.add_child(_shape_panel(pattern_color, Vector2(118, 92), Vector2(34, 28), 16))
		parent.add_child(_shape_panel(pattern_color, Vector2(238, 130), Vector2(42, 34), 20))
		parent.add_child(_shape_panel(pattern_color, Vector2(174, 190), Vector2(30, 24), 14))
	elif pattern_id == "crack_01":
		parent.add_child(_face_label("⌁", Vector2(188, 78), 72, pattern_color))
		parent.add_child(_face_label("╱", Vector2(224, 116), 58, pattern_color))
	elif pattern_id == "stripe_01":
		parent.add_child(_shape_panel(pattern_color, Vector2(110, 92), Vector2(190, 18), 8))
		parent.add_child(_shape_panel(pattern_color, Vector2(92, 152), Vector2(218, 18), 8))

func _add_fallback_accessory(parent: Control, recipe: Dictionary) -> void:
	var accessory_id = str(recipe.get("accessory", "none"))
	if accessory_id == "none":
		return
	var accessory_color = enemy_visual_generator.palette_color(int(recipe.get("accessory_palette", 0)), "accessory")
	accessory_color.a = 0.82
	if accessory_id == "leaf_01":
		parent.add_child(_shape_panel(accessory_color, Vector2(130, 22), Vector2(72, 34), 24))
	elif accessory_id == "ring_01":
		parent.add_child(_face_label("○", Vector2(256, 42), 72, accessory_color))
	elif accessory_id == "patch_01":
		parent.add_child(_shape_panel(accessory_color, Vector2(88, 178), Vector2(70, 40), 8))

func _fallback_eye_text(eye_id: String) -> String:
	if eye_id == "sleepy_01":
		return "－  －"
	if eye_id == "wide_01":
		return "●  ●"
	return "・  ・"

func _fallback_single_eye_text(eye_id: String) -> String:
	if eye_id == "sleepy_01":
		return "－"
	if eye_id == "wide_01":
		return "●"
	return "・"

func _fallback_mouth_text(mouth_id: String) -> String:
	if mouth_id == "open_01":
		return "○"
	if mouth_id == "flat_01":
		return "___"
	return "⌣"

func _shape_panel(color: Color, position_value: Vector2, size_value: Vector2, radius: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1.0, 1.0, 1.0, 0.28)
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _face_label(text: String, position_value: Vector2, size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.position = position_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _catalog_vector(value, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return fallback
	return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))

func _catalog_size(value, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return fallback
	return Vector2(float(value.get("w", fallback.x)), float(value.get("h", fallback.y)))

func _ensure_combat_signals() -> void:
	if game_state == null or game_state.combat_session == null:
		return
	if connected_combat_session == game_state.combat_session:
		return
	connected_combat_session = game_state.combat_session
	var callback = Callable(self, "_on_enemy_damaged")
	if not connected_combat_session.enemy_damaged.is_connected(callback):
		connected_combat_session.enemy_damaged.connect(callback)

func _tick_damage_popups(delta: float) -> void:
	for popup in damage_popups:
		popup["time"] = float(popup["time"]) - delta
	var alive: Array = []
	for popup in damage_popups:
		if float(popup["time"]) > 0.0:
			alive.append(popup)
	damage_popups = alive

func _render_damage_popups(arena: Control) -> void:
	for popup in damage_popups:
		var label = Label.new()
		label.text = str(popup.get("text", ""))
		label.position = Vector2(float(popup.get("x", 900.0)), float(popup.get("y", 320.0)) - (0.8 - float(popup.get("time", 0.0))) * 42.0)
		label.add_theme_font_size_override("font_size", 42)
		label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.20))
		label.add_theme_color_override("font_shadow_color", Color(0.05, 0.08, 0.16))
		label.add_theme_constant_override("shadow_offset_x", 3)
		label.add_theme_constant_override("shadow_offset_y", 3)
		arena.add_child(label)

func _render_characters() -> void:
	var root = HBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 18)
	content_root.add_child(root)

	var roster = _panel(Vector2(560, 0))
	root.add_child(roster)
	var roster_box = VBoxContainer.new()
	roster_box.add_theme_constant_override("separation", 12)
	roster.add_child(roster_box)
	roster_box.add_child(_heading("なかま  %d / 50" % game_state.debug_character_states.size()))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	roster_box.add_child(grid)
	for index in range(0, game_state.debug_character_states.size()):
		grid.add_child(_character_select_card(index))

	var selected = _selected_character_pair()
	var detail = _panel(Vector2(720, 0))
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(detail)
	var detail_box = VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 14)
	detail.add_child(detail_box)
	detail_box.add_child(_heading("%s  %s" % [selected["definition"].rarity, _character_display_name(selected["definition"])]))
	detail_box.add_child(_character_card(selected["definition"], selected["state"], Vector2(330, 320), false))
	detail_box.add_child(_label("Lv.%d / 30    なじみ %d / 3" % [selected["state"].level, selected["state"].najimi], 30))
	var combat_state = game_state.combat_state_for_character(selected["definition"].character_id)
	detail_box.add_child(_label("攻撃力 %s\n攻撃速度 %.2f / s\n元素 %s" % [_format_number(combat_state.final_attack), combat_state.final_attack_speed, _element_display_name(selected["definition"].element)], 28))
	var level_cost = game_state.character_stat_service.level_up_cost(selected["state"].level)
	detail_box.add_child(_label("次のLvアップ: おやつ %d" % level_cost, 26))
	var level_button = _button("レベルアップ", Vector2(300, 72))
	level_button.disabled = level_cost <= 0
	level_button.pressed.connect(_on_character_level_up_pressed)
	detail_box.add_child(level_button)

	var right = _panel(Vector2(430, 0))
	root.add_child(right)
	var right_box = VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 14)
	right.add_child(right_box)
	right_box.add_child(_right_tab_row("character", character_right_tab))
	_render_character_right_tab(right_box, selected["definition"], selected["state"])

func _render_team() -> void:
	var root = HBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 18)
	content_root.add_child(root)

	var left = _panel(Vector2(420, 0))
	root.add_child(left)
	var left_box = VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 10)
	left.add_child(left_box)
	left_box.add_child(_heading("なかま"))
	for index in range(0, game_state.debug_character_states.size()):
		var state = game_state.debug_character_states[index]
		var pair = _character_pair(state.character_id)
		if pair.is_empty():
			continue
		var definition = pair["definition"]
		var assign_button = _button("%s  %s  Lv.%d" % [definition.rarity, _character_display_name(definition), state.level], Vector2(0, 70))
		assign_button.pressed.connect(_on_assign_selected_team_member.bind(definition.character_id))
		left_box.add_child(assign_button)

	var center = _panel(Vector2(790, 0))
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var center_box = VBoxContainer.new()
	center_box.add_theme_constant_override("separation", 20)
	center.add_child(center_box)
	var header = HBoxContainer.new()
	header.add_child(_heading("ちーむ編成"))
	for slot in range(0, 3):
		var button = _button("ちーむ%d" % (slot + 1), Vector2(150, 64))
		button.pressed.connect(_on_team_slot_pressed.bind(slot))
		header.add_child(button)
	center_box.add_child(header)
	var members = HBoxContainer.new()
	members.alignment = BoxContainer.ALIGNMENT_CENTER
	members.add_theme_constant_override("separation", 14)
	center_box.add_child(members)
	var member_ids = game_state.team_state.current_members()
	for index in range(0, member_ids.size()):
		var character_id = member_ids[index]
		var pair = _character_pair(character_id)
		if pair.is_empty():
			continue
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(_label("%d" % (index + 1), 30))
		box.add_child(_character_card(pair["definition"], pair["state"], Vector2(170, 230), true))
		var choose = _button("選択", Vector2(170, 60))
		if index == selected_team_member_index:
			choose.add_theme_stylebox_override("normal", selected_card_style)
		choose.pressed.connect(_on_team_member_slot_pressed.bind(index))
		box.add_child(choose)
		members.add_child(box)

	var right = _panel(Vector2(430, 0))
	root.add_child(right)
	var right_box = VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 16)
	right.add_child(right_box)
	right_box.add_child(_right_tab_row("team", team_right_tab))
	_render_team_right_tab(right_box)

func _render_equipment() -> void:
	var root = HBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 18)
	content_root.add_child(root)

	var categories = _panel(Vector2(210, 0))
	root.add_child(categories)
	var category_box = VBoxContainer.new()
	category_box.add_theme_constant_override("separation", 14)
	categories.add_child(category_box)
	var equipment_button = _button("X そうび", Vector2(0, 90))
	equipment_button.pressed.connect(_on_equipment_category_pressed.bind("equipment"))
	category_box.add_child(equipment_button)
	var shard_button = _button("◇ カケラ", Vector2(0, 90))
	shard_button.pressed.connect(_on_equipment_category_pressed.bind("shard"))
	category_box.add_child(shard_button)
	var other_button = _button("□ その他", Vector2(0, 90))
	other_button.pressed.connect(_on_equipment_category_pressed.bind("other"))
	category_box.add_child(other_button)

	var inventory = _panel(Vector2(470, 0))
	root.add_child(inventory)
	var inv_box = VBoxContainer.new()
	inv_box.add_theme_constant_override("separation", 12)
	inventory.add_child(inv_box)
	inv_box.add_child(_heading(_equipment_inventory_heading()))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	inv_box.add_child(grid)
	if equipment_category == "equipment":
		for equipment_id in game_state.debug_equipment_states.keys():
			var button = _button(_equipment_card_text(equipment_id), Vector2(138, 154))
			if equipment_id == selected_equipment_id:
				button.add_theme_stylebox_override("normal", selected_card_style)
			button.pressed.connect(_on_equipment_selected.bind(equipment_id))
			grid.add_child(button)
	elif equipment_category == "shard":
		for shard_id in game_state.shard_inventory.shards.keys():
			var button = _button(_shard_card_text(shard_id), Vector2(138, 154))
			if shard_id == selected_shard_id:
				button.add_theme_stylebox_override("normal", selected_card_style)
			button.pressed.connect(_on_shard_selected.bind(shard_id))
			grid.add_child(button)
	else:
		inv_box.add_child(_label("その他カテゴリは、今後の素材表示用です。", 26))

	var detail = _panel(Vector2(700, 0))
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(detail)
	var detail_box = VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 18)
	detail.add_child(detail_box)
	if equipment_category == "shard":
		_render_shard_detail(detail_box)
	else:
		_render_equipment_detail(detail_box)

	var side = _panel(Vector2(390, 0))
	root.add_child(side)
	var side_box = VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 16)
	side.add_child(side_box)
	side_box.add_child(_heading("装備中のなかま"))
	side_box.add_child(_label(_equipment_assignment_summary(), 24))
	var equip_button = _button("選択なかまに装備", Vector2(0, 70))
	equip_button.pressed.connect(_on_equip_selected_to_character)
	side_box.add_child(equip_button)

func _render_gacha() -> void:
	if game_state.tutorial_gacha_reward_claimed and not game_state.tutorial_ten_pull_completed:
		gacha_category = "character"
	var root = HBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 18)
	content_root.add_child(root)

	var side = _panel(Vector2(230, 0))
	root.add_child(side)
	var side_box = VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 14)
	side.add_child(side_box)
	var character_gacha_tab = _button("◎ なかま", Vector2(0, 90))
	if gacha_category == "character":
		character_gacha_tab.add_theme_stylebox_override("normal", active_button_style)
	character_gacha_tab.pressed.connect(_on_gacha_category_pressed.bind("character"))
	side_box.add_child(character_gacha_tab)
	var equipment_gacha_tab = _button("X もちもの", Vector2(0, 90))
	if gacha_category == "equipment":
		equipment_gacha_tab.add_theme_stylebox_override("normal", active_button_style)
	equipment_gacha_tab.disabled = game_state.tutorial_gacha_reward_claimed and not game_state.tutorial_ten_pull_completed
	equipment_gacha_tab.pressed.connect(_on_gacha_category_pressed.bind("equipment"))
	side_box.add_child(equipment_gacha_tab)

	var center = _panel(Vector2(0, 0))
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var center_box = VBoxContainer.new()
	center_box.add_theme_constant_override("separation", 18)
	center.add_child(center_box)
	center_box.add_child(_heading(_gacha_heading()))
	center_box.add_child(_label(_gacha_description(), 30))
	var showcase = HBoxContainer.new()
	showcase.alignment = BoxContainer.ALIGNMENT_CENTER
	showcase.add_theme_constant_override("separation", 18)
	showcase.add_theme_stylebox_override("panel", accent_panel_style)
	center_box.add_child(showcase)
	_add_gacha_showcase(showcase)
	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	center_box.add_child(buttons)
	var single = _button("1回  50", Vector2(330, 82))
	single.disabled = game_state.tutorial_gacha_reward_claimed and not game_state.tutorial_ten_pull_completed
	single.pressed.connect(_on_gacha_single_pressed)
	buttons.add_child(single)
	var ten = _button("10回  500", Vector2(360, 82))
	ten.pressed.connect(_on_gacha_ten_pressed)
	buttons.add_child(ten)
	if not last_gacha_results.is_empty():
		center_box.add_child(_label(_gacha_result_text(), 24))

	var rate = _panel(Vector2(350, 0))
	root.add_child(rate)
	var rate_box = VBoxContainer.new()
	rate_box.add_theme_constant_override("separation", 16)
	rate.add_child(rate_box)
	rate_box.add_child(_heading("提供割合"))
	rate_box.add_child(_label("SSR   1%\nSR    10%\nR     34%\nN     55%", 30))
	rate_box.add_child(_label("デイリーボーナス\nひかり石 x500", 28))

func _render_return() -> void:
	var root = HBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 18)
	content_root.add_child(root)

	var main = _panel(Vector2(0, 0))
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(main)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	main.add_child(box)
	box.add_child(_heading("きかん"))
	box.add_child(_label("現在 Stage %d\n今回の最高 Stage %d\n次のきかん条件 Stage %d" % [
		game_state.current_stage(),
		game_state.stage_progression.highest_stage_in_run,
		game_state.return_service.required_return_stage(game_state.return_state)
	], 34))
	var return_button = _button("きかんする", Vector2(360, 82))
	return_button.disabled = not game_state.can_return()
	return_button.pressed.connect(_on_return_pressed)
	box.add_child(return_button)
	box.add_child(_label("きかんするとStage 1に戻り、なかま・もちもの・カケラ・マイルストーンは維持されます。", 28))

	var side = _panel(Vector2(460, 0))
	root.add_child(side)
	var side_box = VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 18)
	side.add_child(side_box)
	side_box.add_child(_heading("マイルストーン"))
	side_box.add_child(_label("獲得済み %d / 10\n永続ダメージ +%.0f%%\n\n100段階初回報酬と500段階マイルストーンは、きかん時にまとめて受け取ります。" % [
		game_state.return_state.milestone_count(),
		game_state.milestone_damage_percent() * 100.0
	], 28))
	var save_row = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 12)
	side_box.add_child(save_row)
	var save_button = _button("Save", Vector2(180, 70))
	save_button.pressed.connect(_on_save_pressed)
	save_row.add_child(save_button)
	var load_button = _button("Load", Vector2(180, 70))
	load_button.pressed.connect(_on_load_pressed)
	save_row.add_child(load_button)

func _render_settings() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.32)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	content_root.add_child(overlay)

	var modal = _panel(Vector2(720, 560))
	modal.anchor_left = 0.5
	modal.anchor_top = 0.5
	modal.anchor_right = 0.5
	modal.anchor_bottom = 0.5
	modal.offset_left = -360.0
	modal.offset_top = -280.0
	modal.offset_right = 360.0
	modal.offset_bottom = 280.0
	content_root.add_child(modal)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	modal.add_child(box)
	var header = HBoxContainer.new()
	header.add_child(_heading("設定"))
	var close = _button("X", Vector2(72, 64))
	close.pressed.connect(_on_settings_close_pressed)
	header.add_child(close)
	box.add_child(header)
	box.add_child(_label("Language", 28))
	box.add_child(_button("日本語", Vector2(0, 68)))
	box.add_child(_label("BGM Volume", 28))
	var bgm = HSlider.new()
	bgm.min_value = 0.0
	bgm.max_value = 100.0
	bgm.value = 70.0
	if audio_manager != null:
		bgm.value = audio_manager.bgm_volume * 100.0
	bgm.custom_minimum_size = Vector2(0, 56)
	bgm.value_changed.connect(_on_bgm_volume_changed)
	box.add_child(bgm)
	box.add_child(_label("SE Volume", 28))
	var se = HSlider.new()
	se.min_value = 0.0
	se.max_value = 100.0
	se.value = 80.0
	if audio_manager != null:
		se.value = audio_manager.se_volume * 100.0
	se.custom_minimum_size = Vector2(0, 56)
	se.value_changed.connect(_on_se_volume_changed)
	box.add_child(se)
	var fullscreen = CheckBox.new()
	fullscreen.text = "Fullscreen"
	fullscreen.add_theme_font_size_override("font_size", 28)
	fullscreen.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	box.add_child(fullscreen)

func _render_equipment_detail(detail_box: VBoxContainer) -> void:
	if game_state.debug_equipment_states.is_empty():
		detail_box.add_child(_heading("もちもの"))
		detail_box.add_child(_label("まだもちものを持っていません。\nであいで手に入れると、ここに表示されます。", 28))
		return
	if not game_state.debug_equipment_states.has(selected_equipment_id):
		selected_equipment_id = str(game_state.debug_equipment_states.keys()[0])
	var state = game_state.debug_equipment_states[selected_equipment_id]
	detail_box.add_child(_heading("%s" % _equipment_display_name(selected_equipment_id)))
	detail_box.add_child(_label("Lv.%d / 30\n基本ステータス\n攻撃力 +%.0f%%" % [state.level, game_state.equipment_attack_percent(selected_equipment_id) * 100.0], 30))
	var sockets = VBoxContainer.new()
	sockets.add_theme_constant_override("separation", 8)
	detail_box.add_child(sockets)
	for index in range(0, state.shard_socket_ids.size()):
		var shard_id = state.shard_socket_ids[index]
		var label = "空き"
		if shard_id != "":
			label = _shard_display_name(shard_id)
		var socket_button = _button("カケラ%d: %s" % [index + 1, label], Vector2(0, 64))
		socket_button.pressed.connect(_on_socket_pressed.bind(index))
		sockets.add_child(socket_button)
	var cost = game_state.equipment_upgrade_service.next_attempt_cost(state)
	detail_box.add_child(_label("次の強化: パーツ %d" % cost, 26))
	var level_button = _button("レベルアップ", Vector2(420, 76))
	level_button.disabled = cost <= 0
	level_button.pressed.connect(_on_equipment_upgrade_pressed)
	detail_box.add_child(level_button)

func _render_shard_detail(detail_box: VBoxContainer) -> void:
	if not game_state.shard_inventory.has_shard(selected_shard_id):
		var keys = game_state.shard_inventory.shards.keys()
		if keys.size() > 0:
			selected_shard_id = str(keys[0])
	if not game_state.shard_inventory.has_shard(selected_shard_id):
		detail_box.add_child(_heading("カケラ"))
		detail_box.add_child(_label("所持カケラがありません。", 28))
		return
	var shard = game_state.shard_inventory.get_shard(selected_shard_id)
	detail_box.add_child(_heading("%s" % _shard_display_name(selected_shard_id)))
	detail_box.add_child(_asset_image("res://assets/shards/main/shard_base.png", Vector2(180, 140), "◇"))
	detail_box.add_child(_label("Lv.%d / 5\n%s +%.1f%%\n%s +%.1f%%" % [
		shard.level,
		_stat_display_name(shard.main_stat),
		shard.current_main_value * 100.0,
		_stat_display_name(shard.sub_stat),
		shard.current_sub_value * 100.0
	], 30))
	var cost = game_state.shard_service.upgrade_cost(shard.level + 1)
	detail_box.add_child(_label("次の強化: 星砂 %d" % cost, 26))
	var upgrade = _button("カケラ強化", Vector2(420, 76))
	upgrade.disabled = cost <= 0
	upgrade.pressed.connect(_on_shard_upgrade_pressed)
	detail_box.add_child(upgrade)

func _gacha_heading() -> String:
	if gacha_category == "equipment":
		return "旅のもちものと であおう！"
	return "いろんな なかまと であおう！"

func _gacha_description() -> String:
	if gacha_category == "equipment":
		return "SSR / SR / R / N のもちものが出ます。10回であう は SR以上 1つ確定。"
	return "SSR / SR / R / N のなかまが出ます。10回であう は SR以上 1つ確定。"

func _add_gacha_showcase(parent: HBoxContainer) -> void:
	if gacha_category == "equipment":
		var shown = 0
		for equipment_id in game_state.debug_equipment_definitions.keys():
			if shown >= 4:
				return
			var state = EquipmentStateScript.new(equipment_id, 1)
			parent.add_child(_equipment_card(equipment_id, state))
			shown += 1
		return
	for index in range(0, min(4, game_state.debug_character_definitions.size())):
		var definition = game_state.debug_character_definitions[index]
		parent.add_child(_character_card(definition, CharacterStateScript.new(definition.character_id, 1, 0), Vector2(190, 230), true))

func _right_tab_row(scope: String, active_tab: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var labels = []
	var ids = []
	if scope == "character":
		labels = ["なじみ", "スキル", "もちもの"]
		ids = ["najimi", "skill", "equipment"]
	else:
		labels = ["ステータス", "スキル", "もちもの"]
		ids = ["status", "skill", "equipment"]
	for index in range(0, ids.size()):
		var button = _button(labels[index], Vector2(126, 62))
		if ids[index] == active_tab:
			button.add_theme_stylebox_override("normal", active_button_style)
		if scope == "character":
			button.pressed.connect(_on_character_right_tab_pressed.bind(ids[index]))
		else:
			button.pressed.connect(_on_team_right_tab_pressed.bind(ids[index]))
		row.add_child(button)
	return row

func _render_character_right_tab(parent: VBoxContainer, definition, state) -> void:
	if character_right_tab == "najimi":
		parent.add_child(_heading("なじみ"))
		parent.add_child(_label("なじみ %d / 3\n\n次のなじみまで\n80 / 100\n\n効果\nLv.1 攻撃力 +5%%\nLv.2 攻撃速度 +5%%\nLv.3 スキル効果 +10%%" % state.najimi, 25))
	elif character_right_tab == "skill":
		parent.add_child(_heading("スキル"))
		parent.add_child(_label("%sのパッシブ\n\n通常攻撃を自動で行います。\nアクティブスキルはありません。\n\n役割: %s\n属性: %s" % [
			_character_display_name(definition),
			definition.archetype,
			_element_display_name(definition.element)
		], 25))
	else:
		parent.add_child(_heading("もちもの"))
		var equipment_id = game_state.equipment_assignment.equipped_equipment_id(definition.character_id)
		if equipment_id == "":
			parent.add_child(_label("装備中のもちものはありません。", 25))
			return
		var equipment_state = game_state.debug_equipment_states[equipment_id]
		parent.add_child(_asset_image(_equipment_asset_path(equipment_id), Vector2(180, 140), "X"))
		parent.add_child(_label("%s\nLv.%d / 30\n攻撃力 +%.0f%%" % [
			_equipment_display_name(equipment_id),
			equipment_state.level,
			game_state.equipment_attack_percent(equipment_id) * 100.0
		], 25))

func _render_team_right_tab(parent: VBoxContainer) -> void:
	var members = game_state.team_state.current_members()
	if team_right_tab == "status":
		parent.add_child(_heading("ステータス"))
		var total_attack = 0.0
		var lines: Array = []
		for character_id in members:
			var pair = _character_pair(str(character_id))
			if pair.is_empty():
				continue
			var combat_state = game_state.combat_state_for_character(pair["definition"].character_id)
			total_attack += combat_state.final_attack
			lines.append("%s  %s" % [_character_display_name(pair["definition"]), _format_number(combat_state.final_attack)])
		lines.insert(0, "合計攻撃力 %s" % _format_number(total_attack))
		parent.add_child(_label("\n".join(lines), 24))
	elif team_right_tab == "skill":
		parent.add_child(_heading("スキル"))
		parent.add_child(_label("チーム内のなかまは全員、自動攻撃とパッシブで戦います。\n\nリーダースキルや手動発動スキルはありません。", 24))
	else:
		parent.add_child(_heading("もちもの"))
		parent.add_child(_label(_team_equipment_summary(), 24))

func _panel(min_size: Vector2) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", panel_style)
	return panel

func _heading(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))
	return label

func _label(text: String, size: int) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))
	return label

func _asset_image(path: String, min_size: Vector2, fallback_text: String) -> Control:
	if path != "" and ResourceLoader.exists(path):
		var rect = TextureRect.new()
		rect.texture = load(path)
		rect.custom_minimum_size = min_size
		rect.expand_mode = 1
		rect.stretch_mode = 5
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return rect
	var fallback = PanelContainer.new()
	fallback.custom_minimum_size = min_size
	fallback.add_theme_stylebox_override("panel", card_style)
	var label = Label.new()
	label.text = fallback_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.05, 0.14, 0.28))
	fallback.add_child(label)
	return fallback

func _character_asset_path(character_id: String) -> String:
	return "res://assets/characters/main/%s.png" % character_id

func _equipment_asset_path(equipment_id: String) -> String:
	return "res://assets/equipment/%s.png" % _equipment_asset_folder_and_name(equipment_id)

func _equipment_asset_folder_and_name(equipment_id: String) -> String:
	var definition = game_state.equipment_definition_for_instance(equipment_id)
	if definition != null:
		equipment_id = definition.equipment_id
	if equipment_id == "equip_stardrop_spear":
		return "weapons/equip_stardrop_spear"
	if equipment_id == "equip_twilight_grimoire":
		return "journey_goods/equip_twilight_grimoire"
	if equipment_id == "equip_sky_spear":
		return "weapons/equip_sky_spear"
	if equipment_id == "equip_young_wind_bow":
		return "weapons/equip_young_wind_bow"
	if equipment_id == "equip_blue_dew_ring":
		return "charms/equip_blue_dew_ring"
	if equipment_id == "equip_windwait_feather":
		return "journey_goods/equip_windwait_feather"
	if equipment_id == "equip_morning_dew_crown":
		return "charms/equip_morning_dew_crown"
	if equipment_id == "equip_traveler_bag":
		return "journey_goods/equip_traveler_bag"
	if equipment_id == "equip_fourleaf_charm":
		return "charms/equip_fourleaf_charm"
	if equipment_id == "equip_forest_mushroom":
		return "journey_goods/equip_forest_mushroom"
	if equipment_id == "equip_lightdrop_bottle":
		return "journey_goods/equip_lightdrop_bottle"
	if equipment_id == "equip_spring_flower_charm":
		return "charms/equip_spring_flower_charm"
	return "journey_goods/%s" % equipment_id

func _enemy_asset_path() -> String:
	if game_state.current_enemy_type() == "boss":
		return "res://assets/enemies/main/boss_lost_great_shard.png"
	return "res://assets/enemies/main/enemy_mugwort_lump.png"

func _background_asset_path() -> String:
	if current_tab == "gacha" and not last_gacha_results.is_empty():
		return "res://assets/backgrounds/common/bg_encounter_night.webp"
	return "res://assets/backgrounds/common/bg_skygarden_day.webp"

func _character_select_card(index: int) -> Button:
	var state = game_state.debug_character_states[index]
	var pair = _character_pair(state.character_id)
	var definition = pair["definition"]
	var button = _button("%s\n%s\nLv.%d" % [definition.rarity, _character_display_name(definition), state.level], Vector2(150, 170))
	if index == selected_character_index:
		button.add_theme_stylebox_override("normal", selected_card_style)
	button.pressed.connect(_on_character_selected.bind(index))
	return button

func _character_card(definition, state, min_size: Vector2, compact: bool) -> PanelContainer:
	var panel = _panel(min_size)
	var style = card_style.duplicate()
	style.border_color = _rarity_color(definition.rarity)
	style.bg_color = Color(1.0, 1.0, 1.0, 0.88)
	if definition.rarity == "SSR":
		style.bg_color = Color(1.0, 0.94, 0.80, 0.92)
	panel.add_theme_stylebox_override("panel", style)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var rarity = _label(definition.rarity, 24)
	rarity.add_theme_color_override("font_color", _rarity_color(definition.rarity))
	box.add_child(rarity)
	var asset = _asset_image(_character_asset_path(definition.character_id), Vector2(140, 120), _element_icon(definition.element))
	if not compact:
		asset.custom_minimum_size = Vector2(210, 170)
	box.add_child(asset)
	var icon = Label.new()
	icon.text = _element_icon(definition.element)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if compact:
		icon.add_theme_font_size_override("font_size", 26)
	else:
		icon.add_theme_font_size_override("font_size", 34)
	icon.add_theme_color_override("font_color", _element_color(definition.element))
	box.add_child(icon)
	var text_size = 30
	var level_size = 30
	if compact:
		text_size = 22
		level_size = 24
	box.add_child(_label(_character_display_name(definition), text_size))
	box.add_child(_label("Lv.%d" % state.level, level_size))
	return panel

func _mini_character_row(definition, state) -> PanelContainer:
	var panel = _panel(Vector2(0, 76))
	var style = card_style.duplicate()
	style.border_color = _rarity_color(definition.rarity)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(_label("%s  %s  Lv.%d" % [definition.rarity, _character_display_name(definition), state.level], 24))
	return panel

func _equipment_card(equipment_id: String, state) -> PanelContainer:
	var panel = _panel(Vector2(125, 150))
	var style = card_style.duplicate()
	style.border_color = Color(0.18, 0.52, 0.90, 0.95)
	panel.add_theme_stylebox_override("panel", style)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var definition = game_state.equipment_definition_for_instance(equipment_id)
	if definition == null:
		return panel
	box.add_child(_label(definition.rarity, 22))
	box.add_child(_asset_image(_equipment_asset_path(equipment_id), Vector2(92, 62), "X"))
	box.add_child(_label(_equipment_display_name(equipment_id), 18))
	box.add_child(_label("Lv.%d" % state.level, 22))
	return panel

func _on_character_selected(index: int) -> void:
	selected_character_index = index
	_render_tab()

func _on_character_level_up_pressed() -> void:
	var selected = _selected_character_pair()
	var result = game_state.level_up_character(selected["definition"].character_id)
	if bool(result.get("success", false)):
		message_label.text = "%s Lv.%d" % [_character_display_name(selected["definition"]), int(result.get("level", 1))]
	else:
		message_label.text = _reason_text(str(result.get("reason", "")), int(result.get("cost", 0)))
	_render_tab()

func _selected_character_pair() -> Dictionary:
	if game_state.debug_character_states.is_empty():
		return {}
	var index = clamp(selected_character_index, 0, game_state.debug_character_states.size() - 1)
	var state = game_state.debug_character_states[index]
	return _character_pair(state.character_id)

func _character_pair(character_id: String) -> Dictionary:
	var definitions = {}
	for definition in game_state.debug_character_definitions:
		definitions[definition.character_id] = definition
	for state in game_state.debug_character_states:
		if state.character_id == character_id and definitions.has(character_id):
			return {
				"definition": definitions[character_id],
				"state": state
			}
	return {}

func _team_summary() -> String:
	var lines: Array = []
	lines.append("Selected Team %d" % (game_state.team_state.selected_team_slot + 1))
	lines.append("変更対象: %d枠目" % (selected_team_member_index + 1))
	for slot in range(0, 3):
		lines.append("")
		lines.append("Team %d" % (slot + 1))
		var members = game_state.team_state.team_members(slot)
		for index in range(0, members.size()):
			var pair = _character_pair(str(members[index]))
			var name = str(members[index])
			if not pair.is_empty():
				name = _character_display_name(pair["definition"])
			lines.append("%d. %s" % [index + 1, name])
	return "\n".join(lines)

func _equipment_inventory_heading() -> String:
	if equipment_category == "shard":
		return "カケラ  %d / %d" % [game_state.shard_inventory.count(), game_state.shard_inventory.inventory_cap]
	if equipment_category == "other":
		return "その他"
	return "そうび  %d / 300" % game_state.debug_equipment_states.size()

func _equipment_card_text(equipment_id: String) -> String:
	var state = game_state.debug_equipment_states[equipment_id]
	var definition = game_state.equipment_definition_for_instance(equipment_id)
	if definition == null:
		return equipment_id
	return "%s\n%s\nLv.%d" % [definition.rarity, _equipment_display_name(equipment_id), state.level]

func _shard_card_text(shard_id: String) -> String:
	var shard = game_state.shard_inventory.get_shard(shard_id)
	if shard == null:
		return shard_id
	return "%s\n%s\nLv.%d" % [shard.rarity, _stat_display_name(shard.main_stat), shard.level]

func _equipment_assignment_summary() -> String:
	var lines: Array = []
	for state in game_state.debug_character_states:
		var pair = _character_pair(state.character_id)
		if pair.is_empty():
			continue
		var definition = pair["definition"]
		var equipment_id = game_state.equipment_assignment.equipped_equipment_id(definition.character_id)
		var equipment_name = "なし"
		if equipment_id != "":
			equipment_name = _equipment_display_name(equipment_id)
		lines.append("%s: %s" % [_character_display_name(definition), equipment_name])
	lines.append("")
	lines.append("選択なかま: %s" % _character_display_name(_selected_character_pair()["definition"]))
	return "\n".join(lines)

func _team_equipment_summary() -> String:
	var lines: Array = []
	var members = game_state.team_state.current_members()
	for character_id in members:
		var pair = _character_pair(str(character_id))
		if pair.is_empty():
			continue
		var equipment_id = game_state.equipment_assignment.equipped_equipment_id(pair["definition"].character_id)
		var equipment_name = "なし"
		if equipment_id != "":
			equipment_name = _equipment_display_name(equipment_id)
		lines.append("%s: %s" % [_character_display_name(pair["definition"]), equipment_name])
	return "\n".join(lines)

func _current_enemy_max_hp() -> float:
	var stage = game_state.current_stage()
	if game_state.current_enemy_type() == "boss":
		return game_state.stage_progression.formula.boss_hp(stage)
	return game_state.stage_progression.formula.normal_enemy_hp(stage)

func _on_return_pressed() -> void:
	var result = game_state.perform_return()
	if bool(result.get("success", false)):
		message_label.text = "Returned: snacks %d, parts %d, stones %d" % [
			int(result.get("snacks", 0)),
			int(result.get("parts", 0)),
			int(result.get("stones", 0))
		]
	else:
		message_label.text = "Return requirement is not met."
	_render_tab()

func _on_character_single_gacha_pressed() -> void:
	var result = game_state.pull_character_gacha(1)
	_show_gacha_result(result)

func _on_character_gacha_pressed() -> void:
	var result = game_state.pull_character_gacha(10)
	_show_gacha_result(result)

func _on_equipment_gacha_pressed() -> void:
	var result = game_state.pull_equipment_gacha(10)
	_show_gacha_result(result)

func _on_gacha_category_pressed(category: String) -> void:
	gacha_category = category
	_render_tab()

func _on_gacha_single_pressed() -> void:
	var result = {}
	if gacha_category == "equipment":
		result = game_state.pull_equipment_gacha(1)
	else:
		result = game_state.pull_character_gacha(1)
	_show_gacha_result(result)

func _on_gacha_ten_pressed() -> void:
	var result = {}
	if gacha_category == "equipment":
		result = game_state.pull_equipment_gacha(10)
	else:
		result = game_state.pull_character_gacha(10)
	_show_gacha_result(result)

func _on_tutorial_reward_pressed() -> void:
	var result = game_state.claim_tutorial_gacha_reward()
	if bool(result.get("success", false)):
		message_label.text = "ひかり石を500受け取りました。"
	else:
		message_label.text = _reason_text(str(result.get("reason", "")), 0)
	_render_tab()

func _on_tutorial_gacha_pressed() -> void:
	gacha_category = "character"
	_set_tab("gacha")

func _show_gacha_result(result: Dictionary) -> void:
	if not bool(result.get("success", false)):
		message_label.text = _reason_text(str(result.get("reason", "")), int(result.get("cost", 0)))
		return
	last_gacha_results = result.get("results", [])
	if game_state.tutorial_ten_pull_completed:
		message_label.text = "10連であい完了。なかまが増えました。"
	else:
		message_label.text = "であい完了。"
	current_tab = "gacha"
	_render_tab()

func _gacha_result_text() -> String:
	var lines: Array = ["最近のであい"]
	for item in last_gacha_results:
		var item_id = str(item.get("item_id", ""))
		lines.append("%s  %s" % [str(item.get("rarity", "")), _gacha_item_display_name(item_id)])
	return "\n".join(lines)

func _on_auto_retry_toggled(enabled: bool) -> void:
	game_state.set_auto_boss_retry_enabled(enabled)

func _on_enemy_damaged(_stage: int, _remaining_hp: float, damage: float) -> void:
	var index = damage_popups.size() % 5
	var offsets = [
		Vector2(720, 330),
		Vector2(1040, 330),
		Vector2(820, 250),
		Vector2(980, 250),
		Vector2(900, 390)
	]
	var offset = offsets[index]
	damage_popups.append({
		"text": _format_number(damage),
		"time": 0.8,
		"x": offset.x,
		"y": offset.y
	})
	if damage_popups.size() > 8:
		damage_popups.pop_front()
	refresh_accumulator = 0.25

func _on_team_slot_pressed(slot: int) -> void:
	game_state.select_team_slot(slot)
	current_tab = "team"
	message_label.text = "Selected Team %d." % (slot + 1)
	_render_tab()

func _on_team_member_slot_pressed(index: int) -> void:
	selected_team_member_index = index
	_render_tab()

func _on_character_right_tab_pressed(tab_id: String) -> void:
	character_right_tab = tab_id
	_render_tab()

func _on_team_right_tab_pressed(tab_id: String) -> void:
	team_right_tab = tab_id
	_render_tab()

func _on_assign_selected_team_member(character_id: String) -> void:
	var result = game_state.set_team_member(selected_team_member_index, character_id)
	if bool(result.get("success", false)):
		message_label.text = "チーム%d枠に設定しました。" % (selected_team_member_index + 1)
	else:
		message_label.text = _reason_text(str(result.get("reason", "")), 0)
	_render_tab()

func _on_equipment_category_pressed(category: String) -> void:
	equipment_category = category
	_render_tab()

func _on_equipment_selected(equipment_id: String) -> void:
	selected_equipment_id = equipment_id
	equipment_category = "equipment"
	_render_tab()

func _on_shard_selected(shard_id: String) -> void:
	selected_shard_id = shard_id
	equipment_category = "shard"
	_render_tab()

func _on_equipment_upgrade_pressed() -> void:
	var result = game_state.upgrade_equipment(selected_equipment_id)
	if bool(result.get("success", false)):
		message_label.text = "装備 Lv.%d" % int(result.get("level_after", 1))
	else:
		message_label.text = _reason_text(str(result.get("reason", "")), int(result.get("cost", 0)))
	_render_tab()

func _on_socket_pressed(socket_index: int) -> void:
	var result = game_state.set_equipment_shard(selected_equipment_id, socket_index, selected_shard_id)
	if bool(result.get("success", false)):
		message_label.text = "カケラを装着しました。"
	else:
		message_label.text = _reason_text(str(result.get("reason", "")), 0)
	_render_tab()

func _on_shard_upgrade_pressed() -> void:
	var result = game_state.upgrade_shard(selected_shard_id)
	if bool(result.get("success", false)):
		message_label.text = "カケラ Lv.%d" % int(result.get("level_after", 1))
	else:
		message_label.text = _reason_text(str(result.get("reason", "")), int(result.get("cost", 0)))
	_render_tab()

func _on_equip_selected_to_character() -> void:
	var selected = _selected_character_pair()
	var result = game_state.equip_item(selected["definition"].character_id, selected_equipment_id)
	if bool(result.get("success", false)):
		message_label.text = "%s に装備しました。" % _character_display_name(selected["definition"])
	else:
		message_label.text = _reason_text(str(result.get("reason", "")), 0)
	_render_tab()

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_bgm_volume_changed(value: float) -> void:
	if audio_manager != null:
		audio_manager.set_bgm_volume(value / 100.0)

func _on_se_volume_changed(value: float) -> void:
	if audio_manager != null:
		audio_manager.set_se_volume(value / 100.0)

func _on_settings_pressed() -> void:
	settings_open = true
	_render_tab()

func _on_settings_close_pressed() -> void:
	settings_open = false
	_render_tab()

func _on_save_pressed() -> void:
	if game_state.save_to_path(SAVE_PATH):
		message_label.text = "Saved to %s." % SAVE_PATH
	else:
		message_label.text = "Save failed."

func _on_load_pressed() -> void:
	var result = game_state.load_from_path(SAVE_PATH)
	if bool(result.get("success", false)):
		var offline_rewards = result.get("offline_rewards", {})
		message_label.text = "Loaded. Offline snacks %d, parts %d." % [
			int(offline_rewards.get("snacks", 0)),
			int(offline_rewards.get("parts", 0))
		]
	else:
		message_label.text = "Load failed."
	_render_tab()

func _rarity_color(rarity: String) -> Color:
	if rarity == "SSR":
		return Color(1.0, 0.34, 0.06)
	if rarity == "SR":
		return Color(0.55, 0.10, 1.0)
	if rarity == "R":
		return Color(0.05, 0.38, 0.78)
	return Color(0.36, 0.46, 0.55)

func _element_icon(element: String) -> String:
	if element == "fire":
		return "F"
	if element == "water":
		return "W"
	if element == "grass":
		return "G"
	return "*"

func _element_color(element: String) -> Color:
	if element == "fire":
		return Color(0.95, 0.20, 0.12)
	if element == "water":
		return Color(0.08, 0.42, 0.95)
	if element == "grass":
		return Color(0.16, 0.62, 0.24)
	return Color(0.42, 0.42, 0.48)

func _element_display_name(element: String) -> String:
	if element == "fire":
		return "火"
	if element == "water":
		return "水"
	if element == "grass":
		return "草"
	return "無"

func _character_display_name(definition) -> String:
	if definition.display_name != "":
		return definition.display_name
	return definition.character_id

func _equipment_display_name(equipment_id: String) -> String:
	var definition = game_state.equipment_definition_for_instance(equipment_id)
	if definition != null:
		if definition.display_name != "":
			return definition.display_name
	return equipment_id

func _shard_display_name(shard_id: String) -> String:
	var names = {
		"shard_inst_attack_critical": "攻めのカケラ",
		"shard_inst_speed_attack": "疾風のカケラ",
		"shard_inst_element_critical_damage": "彩りのカケラ"
	}
	return str(names.get(shard_id, shard_id))

func _stat_display_name(stat_id: String) -> String:
	if stat_id == "attack_percent":
		return "攻撃力"
	if stat_id == "critical_rate":
		return "会心率"
	if stat_id == "critical_damage":
		return "会心ダメージ"
	if stat_id == "attack_speed_percent":
		return "攻撃速度"
	if stat_id == "element_damage_percent":
		return "元素ダメージ"
	return stat_id

func _reason_text(reason: String, cost: int) -> String:
	if reason == "not_enough_snacks":
		return "おやつが足りません。必要数: %d" % cost
	if reason == "not_enough_parts":
		return "パーツが足りません。必要数: %d" % cost
	if reason == "not_enough_shard_material":
		return "星砂が足りません。必要数: %d" % cost
	if reason == "not_enough_stones":
		return "ひかり石が足りません。必要数: %d" % cost
	if reason == "max_level":
		return "これ以上レベルアップできません。"
	if reason == "already_claimed":
		return "すでに受け取り済みです。"
	if reason == "duplicate_character":
		return "同じなかまは同じチームに入れられません。"
	if reason == "unknown_character":
		return "なかまが見つかりません。"
	if reason == "unknown_equipment":
		return "装備が見つかりません。"
	if reason == "unknown_shard":
		return "カケラが見つかりません。"
	return "操作できませんでした。"

func _gacha_item_display_name(item_id: String) -> String:
	var names = {
		"char_pote": "ぽて",
		"char_nemurin": "ねむりん",
		"char_kuromo": "くろも",
		"char_ururu": "うるる",
		"char_nobiru": "のびる",
		"char_hakonya": "はこにゃ",
		"char_mofuri": "もふり",
		"char_kokemaru": "こけまる",
		"char_shiromaru": "しろまる",
		"char_pyon": "ぴょん",
		"char_zun": "ずん",
		"char_meteor": "メテオ",
		"equip_stardrop_spear": "星しずくの槍",
		"equip_twilight_grimoire": "宵書のしるべ",
		"equip_sky_spear": "空色の小槍",
		"equip_young_wind_bow": "若風の弓",
		"equip_blue_dew_ring": "青露のゆびわ",
		"equip_windwait_feather": "風待ちの羽根",
		"equip_morning_dew_crown": "朝露のかんむり",
		"equip_traveler_bag": "旅人のかばん",
		"equip_fourleaf_charm": "四つ葉のおまもり",
		"equip_forest_mushroom": "森のこのこ",
		"equip_lightdrop_bottle": "ひかり雫のびん",
		"equip_spring_flower_charm": "はる花のおまもり"
	}
	return str(names.get(item_id, item_id))

func _enemy_display_name() -> String:
	if game_state.current_enemy_type() == "boss":
		return "まよいの大カケラ"
	return "よもぎのかたまり"

func _format_number(value: float) -> String:
	if value >= 1000000000.0:
		return "%.2fB" % (value / 1000000000.0)
	if value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	if value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	return "%.0f" % value
