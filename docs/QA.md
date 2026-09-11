# QA / Tests

Automate stable formulas and boundaries.

## RequiredDPS
Verify approximately:
S1=10; S1000=1M; S2000=50M; S3000=250M; S5000=1B.
Test boundaries 999/1000/1001, 1999/2000/2001, 2999/3000/3001 and ensure no discontinuity.

## Enemy
NormalEnemyHP(s) == RequiredDPS(s)*5.

## Elements
Test all 16 element attacker/target combinations.

## Shards
main != sub; Lv1..5; acquisition/growth within configured ranges; deterministic seeded reproduction.

## Return
99 cannot first-return; 100 can; requirement +100 and caps at 5000; stage resets to 1; persistent progression remains; multiple crossed milestones all claim exactly once.

## Equipment
Failure consumes parts, does not lower level/destroy item/increase odds.

## Gacha
Seeded simulations reproduce. Large-sample rate sanity test. 10-pull SR+ guarantee always holds.

## Save
Round trip, migration/schema, invalid ID, negative currency, duplicate equipment/shard assignment and truncated/corrupt data recovery.
