# AGENTS.md

## Project
Godot 4.x prototype of 「カケラのせかい（仮）」.
This is the gameplay/balance reference implementation for a future VRChat/UdonSharp port.
Use GDScript.

## Source of truth
Detailed specifications are under `docs/`. Do NOT read every document for every task.
Identify the subsystem involved and read only the relevant documents.

- overall product/game loop → `docs/GAME_DESIGN.md`
- combat/stages/bosses/elements/reactions → `docs/COMBAT.md`
- characters/levels/passives/najimi → `docs/CHARACTER.md`
- equipment → `docs/EQUIPMENT.md`
- shards → `docs/SHARD.md`
- gacha → `docs/GACHA.md`
- return/prestige/economy → `docs/RETURN.md`
- formulas/tables/balance targets → `docs/BALANCE.md` and `data/balance.json`
- UI → `docs/UI.md`
- save/data architecture → `docs/SAVE.md`
- offline → `docs/OFFLINE.md`
- Godot architecture → `docs/GODOT.md`
- future VRChat constraints → `docs/VRCHAT_PORT.md`
- QA → `docs/QA.md`
- undecided items → `docs/OPEN_QUESTIONS.md`
- implementation order → `docs/ROADMAP.md`

Read additional docs only when a task crosses subsystem boundaries.

Specification priority:
1. newest explicit user instruction
2. `[LOCKED]`
3. `data/balance.json` for implemented numeric constants
4. relevant specification
5. `[PROVISIONAL]`
6. current implementation

Never permanently decide `[UNRESOLVED]` values yourself.

## Development principles
- Separate gameplay rules from UI.
- Keep balance values data-driven; do not scatter magic balance numbers.
- Separate static definitions from player-owned state.
- Never use display names as persistent IDs.
- Route gameplay RNG through one RNG service and support deterministic debug seeds.
- Cache final stats; recalculate only after relevant state changes.
- Gameplay must not depend on animation completion.
- Prefer simple explicit code that can later be ported to UdonSharp.
- Do not add unspecified systems.
- Do not perform unrelated refactors.

## UI
Reference resolution: 1920x1080, 16:9. Validate at 1280x720.
Use Control/Container layouts. Design for future VRChat world-space interaction:
large controls, readable text, no hover-only interaction, no required drag-and-drop.

## Workflow
Before implementation:
1. inspect existing code and git status
2. identify and read only relevant docs
3. make the smallest coherent implementation
4. add/update tests
5. run tests
6. summarize changed behavior/files

When asked what to do next, compare implementation with relevant docs, run tests, identify blockers, and recommend the next smallest vertical milestone.
When authorized to implement, implement and test rather than only explaining.
