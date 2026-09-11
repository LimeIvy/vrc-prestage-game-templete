# Combat, Stage, Elements and Reactions

## Core combat
[LOCKED] One enemy at a time. One normal kill advances exactly one stage. Enemies do not attack. Allies have no HP. Four selected characters attack automatically.

[LOCKED] Boss every 50 stages.
Boss win → next stage.
Boss fail → previous normal stage/farm loop.
Only player-facing retry option: `敗北時自動再挑戦 ON/OFF`.

## Required DPS
See `BALANCE.md` and `data/balance.json`.

[LOCKED] Normal enemy HP:
`NormalEnemyHP = RequiredDPS(stage) * 5.0`

[PROVISIONAL] Boss time limit = 15 sec.
`BossHP = RequiredDPS(stage) * BossTimeLimit`.

## Stats
Percentage model. No flat attack and no HP.
`FinalAttack = BaseAttack * (1 + TotalAttackPercent)`
`FinalAttackSpeed = BaseAttackSpeed * (1 + TotalAttackSpeedPercent)`
Active crit: roll each attack. On crit multiply by `1 + CritDamage`.
Expected crit multiplier: `1 + CritRate * CritDamage`.

Stat categories add internally, then categories multiply.

## Elements
[LOCKED] 火→草→水→火.
Advantage ×1.2, disadvantage ×0.8, neutral ×1.0.
無 is always ×1.0 and never reacts.

## Application
[LOCKED] Base application rate 20%.
[PROVISIONAL] Duration 5 sec.
Same element refreshes duration and does not react.
Two different reactive elements trigger reaction and consume both applications.
Reaction effects survive consumption. Different reaction effects may coexist.
Same reaction does not stack; retrigger refreshes duration.
The reactor is the character whose application completes the pair.
Damage reactions use reactor attack and cannot crit.

R status-specialist total application:
- 0凸 30%
- 1凸 45%
- 2凸 65%
- 3凸 90%
This 90% niche is deliberate and should not be trivially matched by SSR.

## Reactions
[PROVISIONAL names/effects]

### 火 + 草 → 延焼
4 sec, 0.5 sec ticks, 8 hits.
Each tick = reactor FinalAttack ×20%; total ×160%.
No crit. Same reaction refreshes, not stacks. Latest reactor may replace source.

### 火 + 水 → 沸騰
Separate extra damage = reactor FinalAttack ×150%.
Triggering normal hit may crit; extra reaction damage cannot.

### 水 + 草 → 繁茂
Whole team attack speed +20% for 5 sec.
Fixed effect. No stacking; retrigger refreshes.
