# Game Design

## Purpose
[LOCKED] Idle/incremental four-character auto-battle game. The Godot build is a reference implementation for a later VRChat/UdonSharp port.

## Core loop
Battle → clear stages → obtain materials/shards → strengthen characters/equipment/shards → beat bosses → きかん → stage resets → old stages become easy → push farther.

## World / terminology
Working title: 「カケラのせかい」, not formally locked.
Cute heavily deformed mascot-like creatures born from miscellaneous forgotten 「カケラ」.
Tone: soft hand-drawn/doodle-like forms, pastel/cream/navy UI.

Terms:
- companions: なかま
- team: ちーむ
- equipment: もちもの
- gacha/acquisition: であい
- prestige: きかん / きかんする
- socket loot: カケラ
- sockets: ソケット
- limit break: なじみ
- duplicate material: おもいで
- element: せいしつ
- character material: おやつ
- equipment material: パーツ
- gacha currency: ひかり石

## Hard exclusions
[DO NOT ADD] Player/ally HP, enemy attacks, healing/defense/tank systems, active skills, manual skill buttons, leader skills, PvP, guilds, battle pass, crafting, main quests, gacha tickets/pity, equipment destruction/downgrade/pity, character-level failure, shard-upgrade failure, multiple equipment slots, recommended formations, dense battle logs.

## Team
[LOCKED] Maximum four characters. Three saved teams.

## Number presentation
[LOCKED] Prefer readable K/M/B/T notation: 999, 1.00K, 824K, 1.00M, 52.4M, 1.24B. Avoid aa/ab notation in designed range.
