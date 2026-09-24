extends SceneTree
const EPSILON = 0.001
const StageFormulaScript = preload("res://systems/progression/stage_formula.gd")
const StageProgressionScript = preload("res://systems/progression/stage_progression.gd")
const ElementServiceScript = preload("res://systems/combat/element_service.gd")
const CombatCharacterStateScript = preload("res://systems/combat/combat_character_state.gd")
const CombatSessionScript = preload("res://systems/combat/combat_session.gd")
const EnemyVisualGeneratorScript = preload("res://systems/enemies/enemy_visual_generator.gd")
const CharacterDefinitionScript = preload("res://systems/characters/character_definition.gd")
const CharacterStateScript = preload("res://systems/characters/character_state.gd")
const CharacterStatServiceScript = preload("res://systems/characters/character_stat_service.gd")
const StatCalculatorScript = preload("res://systems/stats/stat_calculator.gd")
const EquipmentDefinitionScript = preload("res://systems/equipment/equipment_definition.gd")
const EquipmentStateScript = preload("res://systems/equipment/equipment_state.gd")
const EquipmentAssignmentScript = preload("res://systems/equipment/equipment_assignment.gd")
const EquipmentServiceScript = preload("res://systems/equipment/equipment_service.gd")
const EquipmentStatServiceScript = preload("res://systems/equipment/equipment_stat_service.gd")
const EquipmentUpgradeServiceScript = preload("res://systems/equipment/equipment_upgrade_service.gd")
const ShardDefinitionScript = preload("res://systems/shards/shard_definition.gd")
const ShardInventoryScript = preload("res://systems/shards/shard_inventory.gd")
const ShardServiceScript = preload("res://systems/shards/shard_service.gd")
const ShardSocketServiceScript = preload("res://systems/shards/shard_socket_service.gd")
const ReturnStateScript = preload("res://systems/return/return_state.gd")
const ReturnServiceScript = preload("res://systems/return/return_service.gd")
const GachaPoolScript = preload("res://systems/gacha/gacha_pool.gd")
const GachaInventoryScript = preload("res://systems/gacha/gacha_inventory.gd")
const GachaServiceScript = preload("res://systems/gacha/gacha_service.gd")
const SaveServiceScript = preload("res://systems/save/save_service.gd")
const OfflineServiceScript = preload("res://systems/offline/offline_service.gd")
const TeamStateScript = preload("res://systems/teams/team_state.gd")

var _failures: Array = []

func _init() -> void:
	var formula = StageFormulaScript.new()
	_test_required_dps_references(formula)
	_test_required_dps_boundaries(formula)
	_test_normal_enemy_hp(formula)
	_test_stage_progression(formula)
	_test_real_time_combat(formula)
	_test_boss_flow(formula)
	_test_enemy_visual_generation()
	_test_character_growth()
	_test_equipment()
	_test_shards()
	_test_data_foundation()
	_test_elements_and_reactions()
	_test_return()
	_test_gacha()
	_test_save_load()
	_test_offline()
	_test_teams_save()
	_finish()

func _test_required_dps_references(formula) -> void:
	_assert_approx(formula.required_dps(1), 10.0, "S1 RequiredDPS")
	_assert_approx(formula.required_dps(1000), 1000000.0, "S1000 RequiredDPS", 2.0)
	_assert_approx(formula.required_dps(2000), 50000000.0, "S2000 RequiredDPS", 100.0)
	_assert_approx(formula.required_dps(3000), 250000000.0, "S3000 RequiredDPS", 1000.0)
	_assert_approx(formula.required_dps(5000), 1000000000.0, "S5000 RequiredDPS", 1.0)

func _test_required_dps_boundaries(formula) -> void:
	for raw_stage in [999, 1000, 1001, 1999, 2000, 2001, 2999, 3000, 3001]:
		var stage: int = raw_stage
		var previous = formula.required_dps(stage - 1)
		var current = formula.required_dps(stage)
		var next = formula.required_dps(stage + 1)
		_assert_true(current >= previous, "RequiredDPS should not decrease at S%d" % stage)
		_assert_true(next >= current, "RequiredDPS should not decrease after S%d" % stage)
		_assert_true(current / previous < 1.02, "RequiredDPS discontinuity before S%d" % stage)
		_assert_true(next / current < 1.02, "RequiredDPS discontinuity after S%d" % stage)

func _test_normal_enemy_hp(formula) -> void:
	for raw_stage in [1, 999, 1000, 1001, 2000, 3000, 5000]:
		var stage: int = raw_stage
		_assert_approx(
			formula.normal_enemy_hp(stage),
			formula.required_dps(stage) * 5.0,
			"NormalEnemyHP S%d" % stage,
			max(EPSILON, formula.required_dps(stage) * 0.000001)
		)

func _test_stage_progression(formula) -> void:
	var progression = StageProgressionScript.new(formula)
	_assert_equal(progression.current_stage, 1, "new save starts at stage 1")
	_assert_approx(progression.current_enemy_hp, 50.0, "stage 1 normal enemy HP")
	progression.defeat_normal_enemy()
	_assert_equal(progression.current_stage, 2, "normal kill advances exactly one stage")
	_assert_approx(progression.current_enemy_hp, formula.normal_enemy_hp(2), "stage 2 normal enemy HP")

func _test_real_time_combat(formula) -> void:
	var progression = StageProgressionScript.new(formula)
	var party: Array = [
		CombatCharacterStateScript.new("test_1", 10.0, 1.0),
		CombatCharacterStateScript.new("test_2", 10.0, 1.0),
		CombatCharacterStateScript.new("test_3", 10.0, 1.0),
		CombatCharacterStateScript.new("test_4", 10.0, 1.0)
	]
	var combat = CombatSessionScript.new(progression, party)
	combat.tick(1.0)
	_assert_equal(progression.current_stage, 1, "partial combat stays on current stage")
	_assert_approx(progression.current_enemy_hp, 10.0, "four attacks damage enemy HP")
	combat.tick(1.0)
	_assert_equal(progression.current_stage, 2, "combat clear advances one stage")
	_assert_approx(progression.current_enemy_hp, formula.normal_enemy_hp(2), "stage clear spawns next enemy")

func _test_boss_flow(formula) -> void:
	var progression = StageProgressionScript.new(formula)
	progression.set_stage(49)
	_assert_equal(progression.current_enemy_type, "normal", "stage 49 is normal")
	progression.defeat_current_enemy()
	_assert_equal(progression.current_stage, 50, "stage 49 clear advances to boss stage")
	_assert_equal(progression.current_enemy_type, "boss", "stage 50 is boss")
	_assert_approx(progression.current_enemy_hp, formula.boss_hp(50), "stage 50 boss HP")

	var win_party: Array = [
		CombatCharacterStateScript.new("winner_1", formula.boss_hp(50), 1.0)
	]
	var win_combat = CombatSessionScript.new(progression, win_party)
	win_combat.tick(1.0)
	_assert_equal(progression.current_stage, 51, "boss win advances to next stage")
	_assert_equal(progression.current_enemy_type, "normal", "stage 51 is normal")

	progression.set_stage(50)
	var no_damage_party: Array = [
		CombatCharacterStateScript.new("timer_1", 0.0, 1.0)
	]
	var fail_combat = CombatSessionScript.new(progression, no_damage_party)
	fail_combat.tick(formula.boss_time_limit_seconds() + 0.1)
	_assert_equal(progression.current_stage, 49, "boss fail returns to previous normal stage")
	_assert_equal(progression.current_enemy_type, "normal", "boss fail spawns normal enemy")
	progression.defeat_current_enemy()
	_assert_equal(progression.current_stage, 50, "auto boss retry on returns to boss after farm stage")

	progression.auto_boss_retry_enabled = false
	progression.set_stage(50)
	var locked_fail_combat = CombatSessionScript.new(progression, no_damage_party)
	locked_fail_combat.tick(formula.boss_time_limit_seconds() + 0.1)
	_assert_equal(progression.current_stage, 49, "boss fail with auto retry off returns to previous normal")
	progression.defeat_current_enemy()
	_assert_equal(progression.current_stage, 49, "auto boss retry off farms previous normal stage")

func _test_enemy_visual_generation() -> void:
	var generator = EnemyVisualGeneratorScript.new()
	var first = generator.recipe_for(1250, 0, 1)
	var second = generator.recipe_for(1250, 0, 1)
	var other_stage = generator.recipe_for(1251, 0, 1)
	_assert_equal(first, second, "enemy visual recipe is deterministic")
	_assert_true(first != other_stage, "enemy visual recipe changes with seed input")
	_assert_equal(int(first.get("version", 0)), 1, "enemy visual recipe stores version")
	_assert_true(first.has("body"), "enemy visual recipe has body")
	_assert_true(first.has("eyes"), "enemy visual recipe has eyes")
	_assert_true(first.has("mouth"), "enemy visual recipe has mouth")

	var body = _catalog_item(generator.catalog.get("bodies", []), str(first.get("body", "")))
	_assert_true(not body.is_empty(), "enemy visual body exists in catalog")
	for body_definition in generator.catalog.get("bodies", []):
		_assert_true(body_definition.has("face_anchor"), "enemy visual body has face anchor")
		_assert_true(body_definition.has("head_anchor"), "enemy visual body has head anchor")
		_assert_true(body_definition.has("eye_spacing"), "enemy visual body has default eye spacing")
		_assert_true(body_definition.has("pattern_area"), "enemy visual body has pattern area")
	var allowed_patterns = body.get("allowed_patterns", [])
	var allowed_accessories = body.get("allowed_accessories", [])
	_assert_true(allowed_patterns.has(str(first.get("pattern", ""))), "enemy visual pattern obeys body rule")
	_assert_true(allowed_accessories.has(str(first.get("accessory", ""))), "enemy visual accessory obeys body rule")

	var eye = generator.part_definition("eye", str(first.get("eyes", "")))
	var mouth = generator.part_definition("mouth", str(first.get("mouth", "")))
	_assert_true(not eye.is_empty(), "enemy visual eye exists in catalog")
	_assert_true(not mouth.is_empty(), "enemy visual mouth exists in catalog")
	_assert_true(eye.has("size"), "enemy visual eye has local part size")
	_assert_true(eye.has("eye_spacing"), "enemy visual eye can override spacing")
	_assert_true(mouth.has("size"), "enemy visual mouth has local part size")
	_assert_true(mouth.has("offset"), "enemy visual mouth has face-relative offset")

func _test_character_growth() -> void:
	var stats = CharacterStatServiceScript.new()
	var ssr = CharacterDefinitionScript.new("test_ssr", "SSR", "fire", "pure_dps", 1.0)
	var sr = CharacterDefinitionScript.new("test_sr", "SR", "water", "pure_dps", 1.0)
	var r = CharacterDefinitionScript.new("test_r", "R", "grass", "pure_dps", 1.0)
	var n = CharacterDefinitionScript.new("test_n", "N", "none", "pure_dps", 1.0)

	_assert_approx(stats.base_attack(ssr, CharacterStateScript.new("test_ssr", 1, 0)), 10.0, "SSR Lv1 base attack")
	_assert_approx(stats.base_attack(sr, CharacterStateScript.new("test_sr", 10, 0)), 78.0, "SR Lv10 base attack")
	_assert_approx(stats.base_attack(r, CharacterStateScript.new("test_r", 20, 0)), 1680.0, "R Lv20 base attack")
	_assert_approx(stats.base_attack(n, CharacterStateScript.new("test_n", 30, 0)), 30000.0, "N Lv30 base attack")

	var clamped_high = CharacterStateScript.new("clamped_high", 99, 9)
	_assert_equal(clamped_high.level, 30, "character level clamps to 30")
	_assert_equal(clamped_high.najimi, 3, "najimi clamps to 3")
	var clamped_low = CharacterStateScript.new("clamped_low", -1, -1)
	_assert_equal(clamped_low.level, 1, "character level clamps to 1")
	_assert_equal(clamped_low.najimi, 0, "najimi clamps to 0")

	_assert_equal(stats.level_up_cost(1), 10, "level 1 to 2 cost")
	_assert_equal(stats.level_up_cost(29), 100000, "level 29 to 30 cost")
	_assert_equal(stats.cumulative_cost_to_level(30), 396075, "cumulative cost to level 30")

	var speed_definition = CharacterDefinitionScript.new("test_speed", "SSR", "fire", "speed", 1.0)
	var speed_state = CharacterStateScript.new("test_speed", 1, 0)
	var combat_state = stats.combat_state(speed_definition, speed_state)
	_assert_approx(combat_state.final_attack, 8.0, "speed archetype attack modifier")
	_assert_approx(combat_state.final_attack_speed, 1.0, "combat attack speed passthrough")
	_assert_true(not stats.is_base_attack_defined(ssr, 2), "unlisted base attack levels remain unresolved")

func _test_equipment() -> void:
	var equipment_stats = EquipmentStatServiceScript.new()
	var character_stats = CharacterStatServiceScript.new()
	var ssr_equipment = EquipmentDefinitionScript.new("test_ssr_weapon", "SSR", "attack")
	var ssr_equipment_state = EquipmentStateScript.new("test_ssr_weapon", 1)
	_assert_approx(equipment_stats.attack_percent(ssr_equipment, ssr_equipment_state), 0.12, "SSR Lv1 equipment attack percent")
	ssr_equipment_state.set_level(30)
	_assert_approx(equipment_stats.attack_percent(ssr_equipment, ssr_equipment_state), 12.0, "SSR Lv30 equipment attack percent")
	_assert_true(not equipment_stats.is_attack_percent_defined(ssr_equipment, 2), "unlisted equipment levels remain unresolved")
	_assert_equal(ssr_equipment_state.shard_socket_ids.size(), 3, "equipment has three shard sockets")

	var character_definition = CharacterDefinitionScript.new("equipped_character", "SSR", "fire", "pure_dps", 1.0)
	var character_state = CharacterStateScript.new("equipped_character", 1, 0)
	ssr_equipment_state.set_level(1)
	var modifiers = equipment_stats.stat_modifiers(ssr_equipment, ssr_equipment_state)
	var combat_state = character_stats.combat_state(character_definition, character_state, modifiers)
	_assert_approx(combat_state.final_attack, 11.2, "equipment attack percent applies to final attack")

	var assignment = EquipmentAssignmentScript.new()
	assignment.equip("equipped_character", "test_ssr_weapon")
	_assert_equal(assignment.equipped_equipment_id("equipped_character"), "test_ssr_weapon", "equipment assignment lookup")
	assignment.equip("equipped_character", "replacement_weapon")
	_assert_equal(assignment.equipped_equipment_id("equipped_character"), "replacement_weapon", "one character has one equipment assignment")

	var upgrade = EquipmentUpgradeServiceScript.new()
	var equipment_state = EquipmentStateScript.new("upgrade_weapon", 4)
	var normal_result = upgrade.attempt_upgrade(equipment_state)
	_assert_true(normal_result["success"], "normal equipment upgrade succeeds")
	_assert_equal(normal_result["cost"], 50, "Lv4 normal upgrade cost")
	_assert_equal(equipment_state.level, 5, "normal upgrade raises level")

	var failed_gate = upgrade.attempt_upgrade(equipment_state, false)
	_assert_true(not failed_gate["success"], "forced gate failure fails")
	_assert_equal(failed_gate["cost"], 100, "Lv5 gate attempt cost")
	_assert_equal(equipment_state.level, 5, "gate failure keeps level")

	var success_gate = upgrade.attempt_upgrade(equipment_state, true)
	_assert_true(success_gate["success"], "forced gate success succeeds")
	_assert_equal(success_gate["cost"], 100, "Lv5 gate success cost")
	_assert_equal(equipment_state.level, 6, "gate success raises level")
	_assert_approx(upgrade.gate_success_chance(5), 0.4, "Lv5 gate chance from balance")

func _test_shards() -> void:
	var shard_service = ShardServiceScript.new()
	var shard = shard_service.create_shard(
		"shard_1",
		"SSR",
		ShardDefinitionScript.STAT_ATTACK_PERCENT,
		ShardDefinitionScript.STAT_ATTACK_SPEED_PERCENT,
		null,
		null
	)
	_assert_true(shard != null, "SSR shard can be created")
	_assert_equal(shard.level, 1, "new shard starts at level 1")
	_assert_equal(shard.main_stat != shard.sub_stat, true, "shard main and sub differ")
	_assert_approx(shard.current_main_value, 1.0, "main starts at fixed level value")
	_assert_approx(shard.current_sub_value, 0.3, "sub starts at fixed level value")
	_assert_equal(shard_service.upgrade_cost(2), 10, "shard Lv1 to 2 cost")

	var upgrade_result = shard_service.upgrade_shard(shard, 0.15, 0.30)
	_assert_true(upgrade_result["success"], "shard upgrade succeeds")
	_assert_equal(upgrade_result["cost"], 10, "shard upgrade consumes configured cost")
	_assert_equal(shard.level, 2, "shard level increases")
	_assert_approx(shard.current_main_value, 2.0, "main grows to fixed level value")
	_assert_approx(shard.current_sub_value, 0.6, "sub grows to fixed level value")

	shard_service.upgrade_shard(shard, 0.15, 0.15)
	shard_service.upgrade_shard(shard, 0.15, 0.15)
	shard_service.upgrade_shard(shard, 0.15, 0.15)
	_assert_equal(shard.level, 5, "shard max level is 5")
	var capped_result = shard_service.upgrade_shard(shard, 0.15, 0.15)
	_assert_true(not capped_result["success"], "max level shard does not upgrade")

	var inventory = ShardInventoryScript.new(1)
	_assert_true(inventory.add_shard(shard), "inventory accepts shard below cap")
	var extra_shard = shard_service.create_shard(
		"shard_2",
		"SSR",
		ShardDefinitionScript.STAT_CRITICAL_RATE,
		ShardDefinitionScript.STAT_CRITICAL_DAMAGE,
		0.10,
		0.20
	)
	_assert_true(not inventory.add_shard(extra_shard), "inventory rejects shard above cap")
	_assert_equal(inventory.count(), 1, "inventory count respects cap")

	var equipment_state = EquipmentStateScript.new("socket_weapon", 1)
	equipment_state.set_shard_socket(0, "shard_1")
	var shard_modifiers = shard_service.equipped_modifiers(equipment_state, inventory)
	_assert_true(shard_modifiers.has(ShardDefinitionScript.STAT_ATTACK_PERCENT), "socketed shard contributes attack")
	_assert_true(shard_modifiers.has(ShardDefinitionScript.STAT_ATTACK_SPEED_PERCENT), "socketed shard contributes attack speed")

	var equipment_definition = EquipmentDefinitionScript.new("socket_weapon", "SSR", "attack")
	var equipment_stats = EquipmentStatServiceScript.new()
	var combined_modifiers = equipment_stats.combined_stat_modifiers(equipment_definition, equipment_state, shard_modifiers)
	var character_stats = CharacterStatServiceScript.new()
	var character_definition = CharacterDefinitionScript.new("shard_user", "SSR", "fire", "pure_dps", 1.0)
	var character_state = CharacterStateScript.new("shard_user", 1, 0)
	var combat_state = character_stats.combat_state(character_definition, character_state, combined_modifiers)
	_assert_true(combat_state.final_attack > 11.2, "shard attack adds beyond equipment attack")
	_assert_true(combat_state.final_attack_speed > 1.0, "shard attack speed affects combat state")

	var invalid_shard = shard_service.create_shard(
		"invalid",
		"SSR",
		ShardDefinitionScript.STAT_ATTACK_PERCENT,
		ShardDefinitionScript.STAT_ATTACK_PERCENT,
		3.0,
		1.0
	)
	_assert_equal(invalid_shard, null, "main and sub cannot match")

func _test_data_foundation() -> void:
	var character_definition = CharacterDefinitionScript.new("char_foundation_a", "SSR", "fire", "pure_dps", 1.0)
	var character_state = CharacterStateScript.new("char_foundation_a", 99, 0)
	_assert_equal(character_state.level, 30, "character max level is 30")

	var equipment_definition = EquipmentDefinitionScript.new("equip_def_shared", "SSR", "attack", "Display Name")
	var equipment_a = EquipmentStateScript.new("equip_inst_a", 99, "equip_def_shared")
	var equipment_b = EquipmentStateScript.new("equip_inst_b", 1, "equip_def_shared")
	_assert_equal(equipment_a.level, 30, "equipment max level is 30")
	_assert_equal(equipment_a.definition_id, "equip_def_shared", "equipment instance keeps definition id")
	_assert_equal(equipment_a.shard_socket_ids.size(), 3, "equipment keeps exactly three sockets")

	var shard_service = ShardServiceScript.new()
	var shard_inventory = ShardInventoryScript.new(10)
	var shard_attack = shard_service.create_shard(
		"shard_inst_attack",
		"SSR",
		ShardDefinitionScript.STAT_ATTACK_PERCENT,
		ShardDefinitionScript.STAT_CRITICAL_RATE,
		3.0,
		0.1,
		"shard_def_ssr"
	)
	var shard_speed = shard_service.create_shard(
		"shard_inst_speed",
		"SSR",
		ShardDefinitionScript.STAT_ATTACK_SPEED_PERCENT,
		ShardDefinitionScript.STAT_ATTACK_PERCENT,
		0.2,
		1.0,
		"shard_def_ssr"
	)
	var invalid_same_stats = shard_service.create_shard(
		"shard_invalid_same",
		"SSR",
		ShardDefinitionScript.STAT_ATTACK_PERCENT,
		ShardDefinitionScript.STAT_ATTACK_PERCENT,
		3.0,
		1.0,
		"shard_def_ssr"
	)
	_assert_equal(invalid_same_stats, null, "main and sub duplicate is rejected")
	_assert_equal(shard_attack.definition_id, "shard_def_ssr", "shard instance keeps definition id")
	shard_inventory.add_shard(shard_attack)
	shard_inventory.add_shard(shard_speed)
	while shard_attack.can_upgrade():
		shard_service.upgrade_shard(shard_attack, 0.15, 0.15)
	_assert_equal(shard_attack.level, 5, "shard max level is 5")

	var equipment_states = {
		"equip_inst_a": equipment_a,
		"equip_inst_b": equipment_b
	}
	var socket_service = ShardSocketServiceScript.new()
	var socket_result = socket_service.socket_shard(equipment_states, shard_inventory, "equip_inst_a", 0, "shard_inst_attack")
	_assert_true(socket_result["success"], "shard can be socketed by instance id")
	var duplicate_socket = socket_service.socket_shard(equipment_states, shard_inventory, "equip_inst_a", 1, "shard_inst_attack")
	_assert_equal(duplicate_socket["reason"], "duplicate_shard", "same shard cannot be socketed twice")
	var move_socket = socket_service.move_shard(equipment_states, shard_inventory, "equip_inst_b", 2, "shard_inst_attack")
	_assert_true(move_socket["success"], "shard can move to another socket")
	_assert_equal(equipment_a.shard_socket_ids[0], "", "moving shard detaches old socket")
	_assert_equal(equipment_b.shard_socket_ids[2], "shard_inst_attack", "moving shard attaches target socket")
	var bad_socket = socket_service.socket_shard(equipment_states, shard_inventory, "equip_inst_b", 3, "shard_inst_speed")
	_assert_equal(bad_socket["reason"], "socket_out_of_range", "socket index outside 0-2 is rejected")
	var unknown_shard = socket_service.socket_shard(equipment_states, shard_inventory, "equip_inst_b", 1, "missing_shard")
	_assert_equal(unknown_shard["reason"], "unknown_shard", "unknown shard id is rejected")

	var assignment = EquipmentAssignmentScript.new()
	var equipment_service = EquipmentServiceScript.new()
	var valid_characters = {"char_foundation_a": true, "char_foundation_b": true}
	var equip_result = equipment_service.equip_to_character("char_foundation_a", "equip_inst_a", valid_characters, equipment_states, assignment)
	_assert_true(equip_result["success"], "equipment can be equipped")
	var move_equipment = equipment_service.equip_to_character("char_foundation_b", "equip_inst_a", valid_characters, equipment_states, assignment)
	_assert_true(move_equipment["success"], "equipment used by another character can move")
	_assert_equal(assignment.equipped_equipment_id("char_foundation_a"), "", "moved equipment leaves old character")
	_assert_equal(assignment.equipped_equipment_id("char_foundation_b"), "equip_inst_a", "moved equipment reaches new character")
	var unknown_equipment = equipment_service.equip_to_character("char_foundation_a", "missing_equipment", valid_characters, equipment_states, assignment)
	_assert_equal(unknown_equipment["reason"], "unknown_equipment", "unknown equipment id is rejected")

	equipment_a.set_shard_socket(0, "shard_inst_attack")
	equipment_a.set_level(1)
	equipment_b.set_shard_socket(2, "")
	var stat_calculator = StatCalculatorScript.new()
	var combat_state = stat_calculator.combat_state(character_definition, CharacterStateScript.new("char_foundation_a", 1, 0), equipment_definition, equipment_a, shard_inventory, 0.0)
	_assert_approx(combat_state.final_attack, 61.2, "equipment and shard attack add once")
	var diff = stat_calculator.socket_stat_delta(equipment_definition, equipment_a, shard_inventory, 1, "shard_inst_speed")
	_assert_true(diff["success"], "socket stat diff can be calculated")
	_assert_true(diff["delta"].has(ShardDefinitionScript.STAT_ATTACK_SPEED_PERCENT), "socket stat diff includes new shard stat")

	var formula = StageFormulaScript.new()
	var stage_progression = StageProgressionScript.new(formula)
	var return_state = ReturnStateScript.new()
	var character_states: Array = [CharacterStateScript.new("char_foundation_a", 1, 0)]
	var save_assignment = EquipmentAssignmentScript.new()
	save_assignment.equip("char_foundation_a", "equip_inst_a")
	var save_service = SaveServiceScript.new()
	var save_data = save_service.create_save(stage_progression, return_state, character_states, equipment_states, save_assignment, GachaInventoryScript.new(), shard_inventory)
	var loaded_equipment = {
		"equip_inst_a": EquipmentStateScript.new("equip_inst_a", 1, "equip_def_shared"),
		"equip_inst_b": EquipmentStateScript.new("equip_inst_b", 1, "equip_def_shared")
	}
	var loaded_shards = ShardInventoryScript.new(10)
	var loaded_assignment = EquipmentAssignmentScript.new()
	save_service.apply_save(save_data, StageProgressionScript.new(formula), ReturnStateScript.new(), character_states, loaded_equipment, loaded_assignment, GachaInventoryScript.new(), loaded_shards)
	_assert_true(loaded_shards.has_shard("shard_inst_attack"), "loaded save keeps shard instance id")
	_assert_equal(loaded_shards.get_shard("shard_inst_attack").definition_id, "shard_def_ssr", "loaded save keeps shard definition id")
	_assert_equal(loaded_equipment["equip_inst_a"].definition_id, "equip_def_shared", "loaded save keeps equipment definition id")
	_assert_equal(loaded_equipment["equip_inst_a"].shard_socket_ids[0], "shard_inst_attack", "loaded save keeps socket relationship")
	_assert_equal(loaded_assignment.equipped_equipment_id("char_foundation_a"), "equip_inst_a", "loaded save keeps equipment assignment")

func _test_elements_and_reactions() -> void:
	var elements = ElementServiceScript.new()
	_assert_approx(elements.damage_multiplier("fire", "grass"), 1.2, "fire advantage against grass")
	_assert_approx(elements.damage_multiplier("grass", "fire"), 0.8, "grass disadvantage against fire")
	_assert_approx(elements.damage_multiplier("none", "fire"), 1.0, "none element is neutral")
	_assert_equal(elements.reaction_for("fire", "water"), "extra_damage", "fire water reaction")
	_assert_equal(elements.reaction_for("fire", "fire"), "", "same element does not react")

	var formula = StageFormulaScript.new()
	var progression = StageProgressionScript.new(formula)
	var fire = CombatCharacterStateScript.new("fire", 10.0, 1.0, "fire", 0.0)
	var water = CombatCharacterStateScript.new("water", 10.0, 1.0, "water", 0.0)
	var grass = CombatCharacterStateScript.new("grass", 10.0, 1.0, "grass", 0.0)
	var combat = CombatSessionScript.new(progression, [fire])
	combat.set_enemy_element("grass")
	combat.tick(1.0)
	_assert_approx(progression.current_enemy_hp, 38.0, "element advantage affects attack damage")

	progression = StageProgressionScript.new(formula)
	combat = CombatSessionScript.new(progression, [fire, water])
	combat.force_application(fire)
	_assert_true(combat.applications.has("fire"), "first element application is stored")
	combat.force_application(fire)
	_assert_true(combat.applications.has("fire"), "same element refreshes without reaction")
	combat.force_application(water)
	_assert_true(not combat.applications.has("fire"), "reaction consumes existing application")
	_assert_approx(progression.current_enemy_hp, 45.0, "fire water reaction deals extra damage")

	progression = StageProgressionScript.new(formula)
	combat = CombatSessionScript.new(progression, [water, grass])
	combat.force_application(water)
	combat.force_application(grass)
	_assert_approx(combat.speed_buff_multiplier, 1.2, "water grass reaction applies speed buff")
	combat.tick(5.1)
	_assert_approx(combat.speed_buff_multiplier, 1.0, "speed buff expires")

	progression = StageProgressionScript.new(formula)
	combat = CombatSessionScript.new(progression, [fire, grass])
	combat.force_application(fire)
	combat.force_application(grass)
	_assert_true(combat.reactions.has("burn"), "fire grass reaction applies burn")
	combat.tick(0.5)
	_assert_approx(progression.current_enemy_hp, 49.25, "burn ticks for reactor attack damage")

	var none = CombatCharacterStateScript.new("none", 10.0, 1.0, "none", 1.0)
	progression = StageProgressionScript.new(formula)
	combat = CombatSessionScript.new(progression, [none])
	combat.force_application(none)
	_assert_equal(combat.applications.size(), 0, "none element never applies")

func _test_return() -> void:
	var formula = StageFormulaScript.new()
	var progression = StageProgressionScript.new(formula)
	var return_state = ReturnStateScript.new()
	var return_service = ReturnServiceScript.new()

	progression.set_stage(99)
	_assert_true(not return_service.can_return(return_state, progression.highest_stage_in_run), "stage 99 cannot first return")
	progression.set_stage(100)
	_assert_true(return_service.can_return(return_state, progression.highest_stage_in_run), "stage 100 can first return")
	var result = return_service.perform_return(return_state, progression)
	_assert_true(result["success"], "return succeeds at requirement")
	_assert_equal(progression.current_stage, 1, "return resets current stage to 1")
	_assert_equal(progression.highest_stage_in_run, 1, "return resets run highest stage")
	_assert_equal(return_state.return_count, 1, "return count increments")
	_assert_equal(return_service.required_return_stage(return_state), 200, "next return requirement advances by 100")
	_assert_equal(return_state.snacks, 200, "stage 100 return grants snacks")
	_assert_equal(return_state.parts, 160, "stage 100 return grants parts")
	_assert_equal(return_state.stones, 50, "stage 100 first-time stones")

	progression.set_stage(1200)
	result = return_service.perform_return(return_state, progression)
	_assert_true(result["success"], "later return succeeds")
	_assert_equal(result["reward_stage"], 1200, "repeatable reward uses highest stage rounded to 100")
	_assert_equal(result["claimed_milestones"].size(), 2, "multiple crossed milestones claim together")
	_assert_true(return_state.has_claimed_milestone(500), "milestone 500 claimed")
	_assert_true(return_state.has_claimed_milestone(1000), "milestone 1000 claimed")
	_assert_approx(return_service.milestone_damage_percent(return_state), 0.10, "two milestones grant additive damage")

	var expected_stones = 50
	for stage in range(200, 1201, 100):
		expected_stones += 50
	expected_stones += 1000
	_assert_equal(return_state.stones, expected_stones, "first-time return and milestone stones accumulate")
	var expected_snacks = 200 + 5750 + 5750 * 4
	var expected_parts = 160 + 4600 + 4600 * 4
	_assert_equal(return_state.snacks, expected_snacks, "milestone material bonus adds 2x per milestone")
	_assert_equal(return_state.parts, expected_parts, "milestone parts bonus adds 2x per milestone")

	return_state.return_count = 99
	_assert_equal(return_service.required_return_stage(return_state), 5000, "return requirement caps at 5000")

	var character_stats = CharacterStatServiceScript.new()
	var character_definition = CharacterDefinitionScript.new("milestone_user", "SSR", "fire", "pure_dps", 1.0)
	var character_state = CharacterStateScript.new("milestone_user", 1, 0)
	var combat_state = character_stats.combat_state(character_definition, character_state, {"milestone_damage_percent": 0.10})
	_assert_approx(combat_state.final_attack, 11.0, "milestone damage affects final attack")

func _test_gacha() -> void:
	var character_pool = GachaPoolScript.default_character_pool()
	var equipment_pool = GachaPoolScript.default_equipment_pool()
	var gacha = GachaServiceScript.new()
	_assert_equal(gacha.cost_for_pulls(1), 50, "single pull cost")
	_assert_equal(gacha.cost_for_pulls(10), 500, "ten pull cost")

	gacha.set_seed(12345)
	var first_results = gacha.pull_ten(character_pool)
	gacha.set_seed(12345)
	var second_results = gacha.pull_ten(character_pool)
	_assert_equal(_gacha_signature(first_results), _gacha_signature(second_results), "seeded gacha reproduces results")
	_assert_true(_has_sr_plus(first_results), "ten pull guarantees SR plus")

	var character_inventory = GachaInventoryScript.new()
	var duplicate_result = {
		"category": GachaPoolScript.CATEGORY_CHARACTER,
		"rarity": "SSR",
		"item_id": "char_ssr_001",
		"guaranteed": false
	}
	character_inventory.add_result(duplicate_result)
	character_inventory.add_result(duplicate_result)
	_assert_true(character_inventory.has_character("char_ssr_001"), "character result unlocks character")
	_assert_equal(character_inventory.character_duplicate_count("char_ssr_001"), 1, "character duplicate grants token")

	var equipment_inventory = GachaInventoryScript.new()
	var equipment_result = {
		"category": GachaPoolScript.CATEGORY_EQUIPMENT,
		"rarity": "SR",
		"item_id": "equip_sr_001",
		"guaranteed": false
	}
	equipment_inventory.add_result(equipment_result)
	equipment_inventory.add_result(equipment_result)
	_assert_equal(equipment_inventory.equipment_count("equip_sr_001"), 2, "equipment duplicates are counted as owned items")

	var limited_pool = GachaPoolScript.new(GachaPoolScript.CATEGORY_CHARACTER, {
		"N": ["n_only"],
		"R": ["r_only"],
		"SR": ["sr_only"],
		"SSR": ["ssr_only"]
	})
	gacha.set_seed(1)
	var guaranteed_results = gacha.pull_ten(limited_pool)
	_assert_true(_has_sr_plus(guaranteed_results), "ten pull guarantee works for configured pool")
	gacha.apply_results(character_inventory, guaranteed_results)
	_assert_true(character_inventory.has_character("sr_only") or character_inventory.has_character("ssr_only"), "applied gacha results update inventory")

func _test_save_load() -> void:
	var formula = StageFormulaScript.new()
	var stage_progression = StageProgressionScript.new(formula)
	stage_progression.set_stage(345)
	stage_progression.auto_boss_retry_enabled = false

	var return_state = ReturnStateScript.new()
	return_state.return_count = 2
	return_state.snacks = 100
	return_state.parts = 200
	return_state.stones = 300
	return_state.claim_return_stage(100)
	return_state.claim_milestone(500)

	var character_states: Array = [
		CharacterStateScript.new("save_char", 10, 2)
	]
	var equipment_states = {
		"save_equip": EquipmentStateScript.new("save_equip", 5)
	}
	equipment_states["save_equip"].set_shard_socket(0, "save_shard")
	var assignment = EquipmentAssignmentScript.new()
	assignment.equip("save_char", "save_equip")

	var gacha_inventory = GachaInventoryScript.new()
	gacha_inventory.add_result({
		"category": GachaPoolScript.CATEGORY_CHARACTER,
		"rarity": "SSR",
		"item_id": "save_char",
		"guaranteed": false
	})
	gacha_inventory.add_result({
		"category": GachaPoolScript.CATEGORY_CHARACTER,
		"rarity": "SSR",
		"item_id": "save_char",
		"guaranteed": false
	})

	var shard_inventory = ShardInventoryScript.new(10)
	var shard_service = ShardServiceScript.new()
	var shard = shard_service.create_shard(
		"save_shard",
		"SSR",
		ShardDefinitionScript.STAT_ATTACK_PERCENT,
		ShardDefinitionScript.STAT_CRITICAL_RATE,
		3.0,
		0.1
	)
	shard_service.upgrade_shard(shard, 0.15, 0.15)
	shard_inventory.add_shard(shard)

	var save_service = SaveServiceScript.new()
	var save_data = save_service.create_save(stage_progression, return_state, character_states, equipment_states, assignment, gacha_inventory, shard_inventory)

	var loaded_progression = StageProgressionScript.new(formula)
	var loaded_return = ReturnStateScript.new()
	var loaded_characters: Array = [
		CharacterStateScript.new("save_char", 1, 0)
	]
	var loaded_equipment = {
		"save_equip": EquipmentStateScript.new("save_equip", 1)
	}
	var loaded_assignment = EquipmentAssignmentScript.new()
	var loaded_gacha = GachaInventoryScript.new()
	var loaded_shards = ShardInventoryScript.new(10)
	var apply_result = save_service.apply_save(save_data, loaded_progression, loaded_return, loaded_characters, loaded_equipment, loaded_assignment, loaded_gacha, loaded_shards)

	_assert_true(apply_result["success"], "save apply succeeds")
	_assert_equal(loaded_progression.current_stage, 345, "current stage restores")
	_assert_equal(loaded_progression.highest_stage_in_run, 345, "run highest restores")
	_assert_true(not loaded_progression.auto_boss_retry_enabled, "auto boss retry restores")
	_assert_equal(loaded_return.return_count, 2, "return count restores")
	_assert_equal(loaded_return.snacks, 100, "snacks restore")
	_assert_equal(loaded_return.parts, 200, "parts restore")
	_assert_equal(loaded_return.stones, 300, "stones restore")
	_assert_true(loaded_return.has_claimed_return_stage(100), "100 stage flag restores")
	_assert_true(loaded_return.has_claimed_milestone(500), "milestone flag restores")
	_assert_equal(loaded_characters[0].level, 10, "character level restores")
	_assert_equal(loaded_characters[0].najimi, 2, "character najimi restores")
	_assert_equal(loaded_equipment["save_equip"].level, 5, "equipment level restores")
	_assert_equal(loaded_equipment["save_equip"].shard_socket_ids[0], "save_shard", "equipment shard socket restores")
	_assert_equal(loaded_assignment.equipped_equipment_id("save_char"), "save_equip", "equipment assignment restores")
	_assert_equal(loaded_gacha.character_duplicate_count("save_char"), 1, "gacha duplicate restores")
	_assert_true(loaded_shards.has_shard("save_shard"), "shard instance restores")
	_assert_equal(loaded_shards.get_shard("save_shard").level, 2, "shard level restores")

	var corrupt_save = save_data.duplicate(true)
	corrupt_save["current_stage"] = -50
	corrupt_save["snacks"] = -10
	corrupt_save["owned_characters"]["save_char"]["level"] = 99
	corrupt_save["owned_characters"]["save_char"]["najimi"] = -5
	corrupt_save["equipment_assignments"]["other_char"] = "save_equip"
	corrupt_save["shard_instances"]["bad_shard"] = {
		"rarity": "SSR",
		"main_stat": ShardDefinitionScript.STAT_ATTACK_PERCENT,
		"sub_stat": ShardDefinitionScript.STAT_ATTACK_PERCENT,
		"initial_main_value": 1.0,
		"initial_sub_value": 1.0,
		"current_main_value": 1.0,
		"current_sub_value": 1.0,
		"level": 1,
		"growth_history": []
	}
	loaded_progression = StageProgressionScript.new(formula)
	loaded_return = ReturnStateScript.new()
	loaded_characters = [CharacterStateScript.new("save_char", 1, 0)]
	loaded_equipment = {"save_equip": EquipmentStateScript.new("save_equip", 1)}
	loaded_assignment = EquipmentAssignmentScript.new()
	loaded_gacha = GachaInventoryScript.new()
	loaded_shards = ShardInventoryScript.new(10)
	apply_result = save_service.apply_save(corrupt_save, loaded_progression, loaded_return, loaded_characters, loaded_equipment, loaded_assignment, loaded_gacha, loaded_shards)
	_assert_equal(loaded_progression.current_stage, 1, "negative stage recovers to 1")
	_assert_equal(loaded_return.snacks, 0, "negative resource clamps to 0")
	_assert_equal(loaded_characters[0].level, 30, "invalid character level clamps")
	_assert_equal(loaded_characters[0].najimi, 0, "invalid najimi clamps")
	_assert_equal(loaded_assignment.equipped_equipment_id("other_char"), "", "duplicate equipment assignment is ignored")
	_assert_true(not loaded_shards.has_shard("bad_shard"), "invalid shard is ignored")

func _test_offline() -> void:
	var formula = StageFormulaScript.new()
	var progression = StageProgressionScript.new(formula)
	progression.set_stage(250)
	var return_state = ReturnStateScript.new()
	return_state.stones = 100
	var offline = OfflineServiceScript.new()
	var rewards = offline.apply_offline(return_state, 3600.0, progression.current_stage)
	_assert_equal(progression.current_stage, 250, "offline does not advance stage")
	_assert_equal(rewards["stage_advance"], 0, "offline stage advance is zero")
	_assert_equal(rewards["stones"], 0, "offline does not grant stones")
	_assert_true(return_state.snacks > 0, "offline grants snacks")
	_assert_true(return_state.parts > 0, "offline grants parts")
	_assert_true(return_state.shard_acquisition_budget > 8.0, "offline grants shard acquisition budget")
	_assert_equal(return_state.stones, 100, "offline keeps stones unchanged")

	var save_service = SaveServiceScript.new()
	var character_states: Array = []
	var equipment_states = {}
	var assignment = EquipmentAssignmentScript.new()
	var gacha_inventory = GachaInventoryScript.new()
	var save_data = save_service.create_save(progression, return_state, character_states, equipment_states, assignment, gacha_inventory)
	var loaded_return = ReturnStateScript.new()
	var loaded_progression = StageProgressionScript.new(formula)
	save_service.apply_save(save_data, loaded_progression, loaded_return, character_states, equipment_states, assignment, gacha_inventory)
	_assert_approx(loaded_return.shard_acquisition_budget, return_state.shard_acquisition_budget, "offline shard budget persists")

	var delayed_save = save_data.duplicate(true)
	delayed_save["last_active_time"] = 1000.0
	var later_rewards = offline.apply_from_save_time(loaded_return, delayed_save, 4600.0, loaded_progression.current_stage)
	_assert_equal(later_rewards["stage_advance"], 0, "offline from save does not advance stage")
	_assert_true(later_rewards["shard_acquisition_budget"] > 8.0, "offline from save grants shard budget")

func _test_teams_save() -> void:
	var formula = StageFormulaScript.new()
	var progression = StageProgressionScript.new(formula)
	var return_state = ReturnStateScript.new()
	var character_states: Array = [
		CharacterStateScript.new("char_a", 1, 0),
		CharacterStateScript.new("char_b", 1, 0),
		CharacterStateScript.new("char_c", 1, 0),
		CharacterStateScript.new("char_d", 1, 0)
	]
	var team_state = TeamStateScript.new(["char_a", "char_b", "char_c", "char_d"])
	team_state.set_team_members(1, ["char_d", "char_c", "char_b", "char_a"])
	team_state.select_slot(1)

	var save_service = SaveServiceScript.new()
	var save_data = save_service.create_save(
		progression,
		return_state,
		character_states,
		{},
		EquipmentAssignmentScript.new(),
		GachaInventoryScript.new(),
		null,
		team_state
	)

	var loaded_team = TeamStateScript.new(["char_a", "char_b", "char_c", "char_d"])
	save_service.apply_save(
		save_data,
		StageProgressionScript.new(formula),
		ReturnStateScript.new(),
		character_states,
		{},
		EquipmentAssignmentScript.new(),
		GachaInventoryScript.new(),
		null,
		loaded_team
	)
	_assert_equal(loaded_team.selected_team_slot, 1, "selected team slot restores")
	_assert_equal(loaded_team.team_members(1)[0], "char_d", "team members restore")
	_assert_equal(loaded_team.team_members(1).size(), 4, "team has four member slots")

	var corrupt_save = save_data.duplicate(true)
	corrupt_save["teams"] = [
		["char_a", "char_a", "unknown", "char_b"],
		["char_c"],
		["char_d", "char_c", "char_b", "char_a"]
	]
	corrupt_save["selected_team_slot"] = 99
	loaded_team = TeamStateScript.new(["char_a", "char_b", "char_c", "char_d"])
	var result = save_service.apply_save(
		corrupt_save,
		StageProgressionScript.new(formula),
		ReturnStateScript.new(),
		character_states,
		{},
		EquipmentAssignmentScript.new(),
		GachaInventoryScript.new(),
		null,
		loaded_team
	)
	_assert_equal(loaded_team.selected_team_slot, 2, "selected team slot clamps")
	_assert_equal(loaded_team.team_members(0)[0], "char_a", "valid team member remains")
	_assert_equal(loaded_team.team_members(0)[1], "char_b", "duplicate and unknown team members are ignored")
	_assert_true(result["warnings"].size() > 0, "invalid team save reports warnings")

func _has_sr_plus(results: Array) -> bool:
	for result in results:
		var rarity = str(result.get("rarity", ""))
		if rarity == "SR" or rarity == "SSR":
			return true
	return false

func _gacha_signature(results: Array) -> String:
	var parts: Array = []
	for result in results:
		parts.append("%s:%s:%s" % [str(result.get("category", "")), str(result.get("rarity", "")), str(result.get("item_id", ""))])
	return "|".join(parts)

func _catalog_item(items, item_id: String) -> Dictionary:
	if typeof(items) != TYPE_ARRAY:
		return {}
	for item in items:
		if str(item.get("id", "")) == item_id:
			return item
	return {}

func _assert_equal(actual, expected, label: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_approx(actual: float, expected: float, label: String, tolerance: float = EPSILON) -> void:
	if abs(actual - expected) > tolerance:
		_failures.append("%s: expected approx %f, got %f" % [label, expected, actual])

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_failures.append(label)

func _finish() -> void:
	if _failures.is_empty():
		print("PASS: stage formula and progression tests")
		quit(0)
		return

	for raw_failure in _failures:
		var failure: String = raw_failure
		push_error(failure)
	quit(1)
