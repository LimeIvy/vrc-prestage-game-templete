extends Control

const SAVE_PATH = "user://save.json"

var game_state
var current_tab: String = "battle"

var stage_label: Label
var enemy_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_label: Label
var boss_timer_label: Label
var resources_label: Label
var return_label: Label
var message_label: Label
var cards_row: HBoxContainer
var content_title: Label
var content_body: Label
var auto_retry_check: CheckBox
var return_button: Button
var team_buttons_row: HBoxContainer

func _ready() -> void:
	game_state = get_node("/root/GameState")
	_build_ui()
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var root = VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 36.0
	root.offset_top = 28.0
	root.offset_right = -36.0
	root.offset_bottom = -28.0
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	var top_bar = HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 72)
	top_bar.add_theme_constant_override("separation", 10)
	root.add_child(top_bar)

	_add_tab_button(top_bar, "Battle", "battle")
	_add_tab_button(top_bar, "Characters", "characters")
	_add_tab_button(top_bar, "Team", "team")
	_add_tab_button(top_bar, "Equipment", "equipment")
	_add_tab_button(top_bar, "Gacha", "gacha")
	_add_tab_button(top_bar, "Return", "return")

	resources_label = Label.new()
	resources_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	resources_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources_label.add_theme_font_size_override("font_size", 28)
	top_bar.add_child(resources_label)

	var main = HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 24)
	root.add_child(main)

	var battle_panel = VBoxContainer.new()
	battle_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_panel.size_flags_stretch_ratio = 2.0
	battle_panel.add_theme_constant_override("separation", 18)
	main.add_child(battle_panel)

	stage_label = Label.new()
	stage_label.add_theme_font_size_override("font_size", 42)
	battle_panel.add_child(stage_label)

	enemy_label = Label.new()
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_font_size_override("font_size", 36)
	battle_panel.add_child(enemy_label)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.custom_minimum_size = Vector2(0, 56)
	enemy_hp_bar.min_value = 0.0
	battle_panel.add_child(enemy_hp_bar)

	enemy_hp_label = Label.new()
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_hp_label.add_theme_font_size_override("font_size", 28)
	battle_panel.add_child(enemy_hp_label)

	boss_timer_label = Label.new()
	boss_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_timer_label.add_theme_font_size_override("font_size", 28)
	battle_panel.add_child(boss_timer_label)

	cards_row = HBoxContainer.new()
	cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)
	battle_panel.add_child(cards_row)

	var side_panel = VBoxContainer.new()
	side_panel.custom_minimum_size = Vector2(470, 0)
	side_panel.add_theme_constant_override("separation", 16)
	main.add_child(side_panel)

	content_title = Label.new()
	content_title.add_theme_font_size_override("font_size", 36)
	side_panel.add_child(content_title)

	content_body = Label.new()
	content_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_body.add_theme_font_size_override("font_size", 26)
	content_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.add_child(content_body)

	team_buttons_row = HBoxContainer.new()
	team_buttons_row.add_theme_constant_override("separation", 10)
	side_panel.add_child(team_buttons_row)
	for slot in range(0, 3):
		var team_button = _make_button("Team %d" % (slot + 1))
		team_button.pressed.connect(_on_team_slot_pressed.bind(slot))
		team_buttons_row.add_child(team_button)

	return_label = Label.new()
	return_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return_label.add_theme_font_size_override("font_size", 26)
	side_panel.add_child(return_label)

	return_button = _make_button("Return")
	return_button.pressed.connect(_on_return_pressed)
	side_panel.add_child(return_button)

	var gacha_row = HBoxContainer.new()
	gacha_row.add_theme_constant_override("separation", 10)
	side_panel.add_child(gacha_row)

	var character_gacha_button = _make_button("Character x10")
	character_gacha_button.pressed.connect(_on_character_gacha_pressed)
	gacha_row.add_child(character_gacha_button)

	var equipment_gacha_button = _make_button("Equipment x10")
	equipment_gacha_button.pressed.connect(_on_equipment_gacha_pressed)
	gacha_row.add_child(equipment_gacha_button)

	auto_retry_check = CheckBox.new()
	auto_retry_check.text = "Boss auto retry"
	auto_retry_check.button_pressed = true
	auto_retry_check.custom_minimum_size = Vector2(0, 64)
	auto_retry_check.add_theme_font_size_override("font_size", 28)
	auto_retry_check.toggled.connect(_on_auto_retry_toggled)
	side_panel.add_child(auto_retry_check)

	var save_row = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 10)
	side_panel.add_child(save_row)

	var save_button = _make_button("Save")
	save_button.pressed.connect(_on_save_pressed)
	save_row.add_child(save_button)

	var load_button = _make_button("Load")
	load_button.pressed.connect(_on_load_pressed)
	save_row.add_child(load_button)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 24)
	side_panel.add_child(message_label)

func _add_tab_button(parent: Control, label: String, tab_id: String) -> void:
	var button = _make_button(label)
	button.pressed.connect(_set_tab.bind(tab_id))
	parent.add_child(button)

func _make_button(label: String) -> Button:
	var button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(150, 64)
	button.add_theme_font_size_override("font_size", 28)
	return button

func _set_tab(tab_id: String) -> void:
	current_tab = tab_id
	_refresh_content()

func _refresh() -> void:
	if game_state == null or game_state.stage_progression == null:
		return

	stage_label.text = "Stage %d" % game_state.current_stage()
	var enemy_type = game_state.current_enemy_type().capitalize()
	enemy_label.text = "%s Enemy" % enemy_type
	var max_hp = _current_enemy_max_hp()
	var current_hp = game_state.current_enemy_hp()
	enemy_hp_bar.max_value = max(max_hp, 1.0)
	enemy_hp_bar.value = clamp(current_hp, 0.0, enemy_hp_bar.max_value)
	enemy_hp_label.text = "HP %s / %s" % [_format_number(current_hp), _format_number(max_hp)]
	if game_state.current_enemy_type() == "boss":
		boss_timer_label.text = "Boss timer %.1fs" % game_state.boss_time_remaining()
	else:
		boss_timer_label.text = ""

	resources_label.text = "Stones %d  Snacks %d  Parts %d" % [
		game_state.return_state.stones,
		game_state.return_state.snacks,
		game_state.return_state.parts
	]
	return_label.text = "Return requirement: Stage %d\nRun best: Stage %d" % [
		game_state.return_service.required_return_stage(game_state.return_state),
		game_state.stage_progression.highest_stage_in_run
	]
	return_button.disabled = not game_state.can_return()
	auto_retry_check.button_pressed = game_state.stage_progression.auto_boss_retry_enabled
	_refresh_cards()
	_refresh_content()

func _refresh_cards() -> void:
	for child in cards_row.get_children():
		child.queue_free()

	for index in range(0, game_state.debug_character_definitions.size()):
		var definition = game_state.debug_character_definitions[index]
		var state = game_state.debug_character_states[index]
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(250, 210)
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		panel.add_child(box)
		var name_label = Label.new()
		name_label.text = definition.character_id
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(name_label)
		var info_label = Label.new()
		info_label.text = "%s  %s\nLv %d  Najimi %d" % [definition.rarity, definition.element, state.level, state.najimi]
		info_label.add_theme_font_size_override("font_size", 24)
		box.add_child(info_label)
		var attack_label = Label.new()
		var combat_state = game_state.character_stat_service.combat_state(definition, state, game_state._equipment_modifiers_for_character(definition.character_id))
		attack_label.text = "ATK %s\nSPD %.2f" % [_format_number(combat_state.final_attack), combat_state.final_attack_speed]
		attack_label.add_theme_font_size_override("font_size", 24)
		box.add_child(attack_label)
		cards_row.add_child(panel)

func _refresh_content() -> void:
	if content_title == null:
		return
	if current_tab == "battle":
		content_title.text = "Battle"
		content_body.text = "One enemy is active. Four characters attack automatically. Bosses appear every 50 stages."
	elif current_tab == "characters":
		content_title.text = "Characters"
		content_body.text = _character_summary()
	elif current_tab == "team":
		content_title.text = "Team"
		content_body.text = _team_summary()
	elif current_tab == "equipment":
		content_title.text = "Equipment"
		content_body.text = _equipment_summary()
	elif current_tab == "gacha":
		content_title.text = "Gacha"
		content_body.text = "Character and equipment gachas are separate.\n10 pulls cost 500 stones and guarantee SR+."
	elif current_tab == "return":
		content_title.text = "Return"
		content_body.text = "Return resets the current run to Stage 1, keeps owned progression, and grants rewards from run best stage."

func _character_summary() -> String:
	var lines: Array = []
	for index in range(0, game_state.debug_character_definitions.size()):
		var definition = game_state.debug_character_definitions[index]
		var state = game_state.debug_character_states[index]
		lines.append("%s  %s  Lv%d  Najimi %d" % [definition.rarity, definition.character_id, state.level, state.najimi])
	return "\n".join(lines)

func _equipment_summary() -> String:
	var lines: Array = []
	for equipment_id in game_state.debug_equipment_states.keys():
		var state = game_state.debug_equipment_states[equipment_id]
		lines.append("%s  Lv%d  sockets %s" % [equipment_id, state.level, str(state.shard_socket_ids)])
	return "\n".join(lines)

func _team_summary() -> String:
	var lines: Array = []
	lines.append("Selected Team %d" % (game_state.team_state.selected_team_slot + 1))
	for slot in range(0, 3):
		lines.append("")
		lines.append("Team %d" % (slot + 1))
		var members = game_state.team_state.team_members(slot)
		for index in range(0, members.size()):
			lines.append("%d. %s" % [index + 1, str(members[index])])
	return "\n".join(lines)

func _current_enemy_max_hp() -> float:
	var stage = game_state.current_stage()
	if game_state.current_enemy_type() == "boss":
		return game_state.stage_progression.formula.boss_hp(stage)
	return game_state.stage_progression.formula.normal_enemy_hp(stage)

func _on_return_pressed() -> void:
	var result = game_state.perform_return()
	if bool(result.get("success", false)):
		message_label.text = "Returned. Rewards: snacks %d, parts %d, stones %d." % [
			int(result.get("snacks", 0)),
			int(result.get("parts", 0)),
			int(result.get("stones", 0))
		]
	else:
		message_label.text = "Return requirement is not met."

func _on_character_gacha_pressed() -> void:
	var result = game_state.pull_character_gacha(10)
	_show_gacha_result(result)

func _on_equipment_gacha_pressed() -> void:
	var result = game_state.pull_equipment_gacha(10)
	_show_gacha_result(result)

func _show_gacha_result(result: Dictionary) -> void:
	if not bool(result.get("success", false)):
		message_label.text = "Not enough stones."
		return
	var results = result.get("results", [])
	var summary: Array = []
	for item in results:
		summary.append("%s %s" % [str(item.get("rarity", "")), str(item.get("item_id", ""))])
	message_label.text = "\n".join(summary)

func _on_auto_retry_toggled(enabled: bool) -> void:
	game_state.set_auto_boss_retry_enabled(enabled)

func _on_team_slot_pressed(slot: int) -> void:
	game_state.select_team_slot(slot)
	current_tab = "team"
	message_label.text = "Selected Team %d." % (slot + 1)
	_refresh()

func _on_save_pressed() -> void:
	if game_state.save_to_path(SAVE_PATH):
		message_label.text = "Saved to %s." % SAVE_PATH
	else:
		message_label.text = "Save failed."

func _on_load_pressed() -> void:
	var result = game_state.load_from_path(SAVE_PATH)
	if bool(result.get("success", false)):
		var offline_rewards = result.get("offline_rewards", {})
		message_label.text = "Loaded. Offline rewards: snacks %d, parts %d." % [
			int(offline_rewards.get("snacks", 0)),
			int(offline_rewards.get("parts", 0))
		]
	else:
		message_label.text = "Load failed."

func _format_number(value: float) -> String:
	if value >= 1000000000.0:
		return "%.2fB" % (value / 1000000000.0)
	if value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	if value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	return "%.0f" % value
