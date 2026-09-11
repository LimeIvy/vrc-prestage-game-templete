# Balance / Formulas / Targets

## Stage RequiredDPS
[LOCKED current curve]

For 1 <= S <= 1000:
`10 * 1.0115911122^(S - 1)`

For 1000 < S <= 2000:
`1,000,000 * 1.003919685^(S - 1000)`

For 2000 < S <= 3000:
`50,000,000 * 1.001610734^(S - 2000)`

For S > 3000:
`250,000,000 * 2^((S - 3000)/1000)`

References:
S1 10; S1000 1M; S2000 50M; S3000 250M; S4000 500M; S5000 1B; S5300 ~1.23B; S6000 2B.

[LOCKED] `NormalEnemyHP = RequiredDPS * 5`.
[PROVISIONAL] `BossHP = RequiredDPS * 15`.

## Expected DPS
`FinalAttack = BaseAttack * (1 + TotalAttackPercent)`
`FinalAttackSpeed = BaseAttackSpeed * (1 + TotalAttackSpeedPercent)`
`ExpectedCritMultiplier = 1 + CritRate * CritDamage`

Balance/offline expected DPS:
`FinalAttack * FinalAttackSpeed * ExpectedCritMultiplier * (1 + ElementDamage%) * PassiveReactionMultiplier * (1 + MilestoneDamagePercent)`

Active play must roll crit per actual attack rather than use expected crit.

## Endgame
Target completion build:
SSR3凸×4, Lv30, SSR equipment Lv30×4, SSR Lv5 shards×12 with good optimized rolls, coherent reactions/passives, all 500-stage milestones.
Target sustained team DPS ~1.1–1.3B.
Expected wall ~STAGE5200–5300.
Perfect shards are not required; theoretical near-perfect optimization may reach ~5500–5700+.
STAGE6000 should be beyond normal current-version completion.

## Progression targets
~500: N/R Lv10–15, equip Lv5–10, N/R shards; ~3–5K DPS.
~1000: R/SR Lv18–22, equip Lv10–15, R/SR shards Lv1–2; ~1–1.5M.
~2000: SR3凸/SSR0, Lv25–28, SR/SSR equip Lv20–25; ~50–70M.
~3000: SSR0–1凸, Lv30, SSR equip Lv25–30; ~250–350M.
~4000: SSR1–2凸, good SSR shards; ~500M+.
~5000: SSR3凸-heavy, near-ideal shards; ~1B.

## Repeatable return materials
STAGE: おやつ / パーツ
100: 200/160
200: 280/220
300: 390/310
400: 550/440
500: 770/620
600: 1080/860
700: 1510/1210
800: 2110/1690
900: 2950/2360
1000: 4130/3300
1100: 4870/3900
1200: 5750/4600
1300: 6780/5420
1400: 8000/6400
1500: 9440/7550
1600: 11140/8910
1700: 13150/10520
1800: 15510/12410
1900: 18300/14640
2000: 21630/17300
2100: 24870/19900
2200: 28600/22880
2300: 32890/26310
2400: 37820/30260
2500: 43500/34800
2600: 50020/40020
2700: 57520/46020
2800: 66150/52920
2900: 76070/60860
3000: 87490/69990
3100: 94490/75590
3200: 102050/81640
3300: 110210/88170
3400: 119030/95220
3500: 128550/102840
3600: 138840/111070
3700: 149950/119960
3800: 161940/129550
3900: 174900/139920
4000: 188890/151110
4100: 204000/163200
4200: 220320/176260
4300: 237950/190360
4400: 256980/205580
4500: 277540/222030
4600: 299740/239790
4700: 323720/258980
4800: 349620/279700
4900: 377590/302070
5000: 407810/326250

This table remains tunable against expected equipment cost and progression simulations.
