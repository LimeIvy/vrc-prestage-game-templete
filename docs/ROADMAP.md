# Implementation Roadmap

Prefer one working vertical slice at a time.

1. Numeric stage prototype: RequiredDPS, normal enemy HP, stage progression.
2. Real-time combat: four characters, attack timers, enemy HP, stage clear.
3. Bosses: every 50, timer, win/fail, auto retry.
4. Character growth: rarity, Lv1–30, base stats, おやつ.
5. Equipment: one item/character, percentage stats, パーツ, gate RNG.
6. Shards: inventory, initial rolls, random growth, three sockets.
7. Elements/reactions.
8. きかん: requirement/reset/rewards/milestones.
9. Gacha: character/equipment/duplicates.
10. Save/load (start basic persistence earlier; by here all core state must persist).
11. Offline progression only after rules are confirmed.
12. UI polish.

Prototype success:
new save starts stage1; four characters auto-attack; normal stages and bosses work; characters/equipment/shards progress; reactions work; three teams save; gacha works; きかん/milestones work; save/load works; simulator can reproduce build numbers and RNG distributions.
