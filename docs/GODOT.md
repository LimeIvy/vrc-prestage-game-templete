# Godot Prototype Architecture

Use Godot 4.x + GDScript.

The prototype is a reference model, not a second fully polished final game. Prioritize correctness, inspectability and balance.

Recommended layout:
```text
res://
  autoload/
    game_state.gd
    data_registry.gd
    save_service.gd
    rng_service.gd
  data/
  systems/
    combat/
    progression/
  ui/
    shared/
    battle/
    characters/
    teams/
    equipment/
    gacha/
    return/
    settings/
  debug/
  tests/
```

Rules:
- UI calls systems; systems update state; signals refresh UI.
- No animation-dependent rules.
- Balance constants loaded centrally.
- Cache final stats; recalc on level/najimi/equipment/shard/team/milestone changes, not every frame.
- Do not full-scan inventory or redraw all UI every frame.
- Prefer feature-based grouping and composition.
- Typed GDScript where practical; snake_case methods/vars, PascalCase class_name, UPPER_SNAKE_CASE constants.
- Small focused methods, explicit enums, immutable definitions after load.
- Avoid giant managers, deep nesting, hidden side effects, magic numbers and unnecessary inheritance.

## Debug tooling required
Add resources, set stages/return count, grant/set characters/equipment, force gate success/fail, generate/force shards/growth, clear inventory/reset save, import/export save.

## Balance simulator required
Inputs: character rarity/level/role/base speed, equipment%, shard stats, crit, speed, element damage, passive/reaction and milestone.
Outputs: base/final attack, speed, expected crit, character/team DPS, reachable stage, normal HP, boss HP.
Batch simulations: equipment attempts, shard generation/quality, gacha, return progression. Report distributions (P10/P50/P90/P95/mean), not averages only.
