# Save / Data Architecture

## Principles
Use schema versioning. Never silently break existing saves.
Static definitions and owned state are separate. Persistent references use stable IDs, never display names.

Conceptual save:
- schema_version
- current_stage
- highest_stage_ever
- current_run_highest_stage
- return_count
- snacks / parts / shard_upgrade_material / hikari_stone
- auto_retry_boss
- selected_team_slot
- teams
- owned_characters
- owned_equipments
- shard_instances
- claimed_100_stage_stone_flags
- claimed_500_stage_milestones
- last_save_time / last_active_time
- language / bgm_volume / se_volume

Validation:
stage >=1; character/equipment level 1..30; shard level 1..5; main != sub; resources >=0; team <=4; no equipment/shard duplicate assignment; IDs valid.
Recover safely when possible and log corruption.

Recommended save triggers:
periodically 30–60 sec; after gacha; equipment/shard enhancement; assignment; return; clean exit. Never every hit.

## RNG
Central RNG service. Deterministic debug seed must reproduce gacha, shard generation/growth and equipment gate results.
