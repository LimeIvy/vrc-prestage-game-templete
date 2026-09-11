# Future VRChat / UdonSharp Port Constraints

The Godot implementation should be easy to rewrite in UdonSharp.

Known design constraints from the VRChat plan:
- PlayerData and PlayerObjects provide persistence.
- Wait for OnPlayerRestored before using persistent player state.
- Keep high-frequency state separate from large persistent blobs.
- Late joiners do not replay old network events; persistent shared state must use synced variables.
- Ownership controls who may change synced variables; do not rely on Instance Master.
- UdonSharp is C#-like but not unrestricted ordinary Unity C#.
- Store shards compactly with numeric IDs/values rather than verbose strings/JSON.
- One-main + one-sub shard model is deliberately compact.
- Paginate/recycle large inventory UI.
- Individual progression should preferably remain local/persistent; only sync data other players need to see.
- Offline rewards should use elapsed time rather than simulate every battle.

[UNRESOLVED] Exact multiplayer visibility/shared state.

UI design reference should remain 1920×1080 / 16:9 so the information hierarchy can be recreated on a VRChat world-space Canvas.
