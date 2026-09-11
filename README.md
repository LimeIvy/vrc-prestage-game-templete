# カケラのせかい（仮） — Codex/Godot development pack

This pack restructures the previous oversized AGENTS.md into:
- a short root `AGENTS.md` that is cheap to load repeatedly
- subsystem-specific `docs/*.md`
- `data/balance.json` for centralized numeric values
- an empty Godot-oriented directory skeleton

Start Codex from this repository root.

Recommended first task:
> Read AGENTS.md and only the docs needed for ROADMAP milestone 1. Implement the numeric stage prototype in Godot 4.x/GDScript, add boundary tests, run them, and report the result. Do not decide unresolved specifications.

Important: the detailed specs preserve the currently agreed design and mark tunable/unresolved items explicitly.
