# Shards / カケラ

This is intended to be the deepest long-term RNG/optimization system.

## Structure
[LOCKED]
Each shard has:
- rarity
- exactly one main stat
- exactly one sub stat
- main != sub
- initial main roll
- initial sub roll
- Lv1..5
- random main growth per upgrade
- random sub growth per upgrade

Stat pool:
attack%, crit rate, crit damage, attack speed%, element damage%.
No flat attack or HP.

## SSR Lv1 main ranges
- attack: 300–375%
- crit rate: 10–12.5%
- crit damage: 50–65%
- attack speed: 20–25%
- element damage: 40–50%

## SSR Lv1 sub ranges
[PROVISIONAL]
- attack: 100–150%
- crit rate: 5–7%
- crit damage: 20–30%
- attack speed: 8–12%
- element damage: 15–25%

N/R/SR sub ranges are [UNRESOLVED].

## Growth
At Lv1→2, 2→3, 3→4, 4→5, both main and sub independently grow.

[PROVISIONAL] Candidate growth tier each level:
+15%, +20%, +25%, or +30% of that stat's original Lv1 rolled value.
Four minimum rolls → final ×1.60 of initial.
Four maximum rolls → final ×2.20.
Growth-tier probabilities are [UNRESOLVED]; keep configurable.

Goal: both initial roll and enhancement rolls matter. A mediocre drop may become excellent; a high initial roll may brick. God-roll pursuit is intentional.

## Upgrade cost
[PROVISIONAL] Dedicated boss shard material:
1→2 10; 2→3 30; 3→4 80; 4→5 200; total 320.
Upgrade always succeeds; randomness is stat growth.

## Acquisition / inventory
[PROVISIONAL] Inventory cap 200.
Target quantity ≈100 shards/12h (~8.33/hour, one per ~7m12s).
Recommended: quantity derives from elapsed-time budget, not kill speed. Progression improves rarity/quality distribution rather than raw quantity. Same-rarity roll ranges should remain stage-independent so old god rolls stay valuable.
Current-stage vs highest-stage quality source is [UNRESOLVED].
Cap/auto-dismantle behavior is [UNRESOLVED].

Endgame STAGE5300 should target roughly 80–85/100 shard quality across 12 slots, not theoretical perfection.
