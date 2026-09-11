# UI / UX

## Reference
[LOCKED development convention] 1920×1080 reference resolution, 16:9.
Validate at 1280×720. Godot window may be resizable; UI scales rather than becoming a mobile layout.
Use Control + Anchor + Containers. Keep essential controls away from extreme edges.

Future VRC readability:
- body ~28–32px at 1920×1080
- secondary ~22–26px
- button/card labels ~28–32px
- headings ~36–44px
- major numbers ~44–64px
- standard button height ~64–72px
- no hover-only interaction
- no required drag-and-drop
- large VR-laser-friendly targets

## Top bar
Unified:
`[戦闘] [なかま] [ちーむ] [もちもの] [であい] [きかん]` + `ひかり石` + menu.
No separate 強化 tab. No title screen.

## Battle
One standalone enemy centered. Above: name + large HP bar. Stage visible.
Damage/reaction text near enemy allowed.
Bottom: exactly four shared character cards.
No ally field models, HP, action gauges, logs or drop-info panel.
Bottom-right only boss-failure auto-retry setting; no AUTO/×2/pause controls.

## Shared character card
Rarity, element icon, same character art, name, Lv. Optional selection/team-slot/equipped markers. No HP/gauge.

## なかま
Left roster grid; center selected card/header + stats + Lvアップ using おやつ only.
Right tabs exactly `なじみ / スキル / もちもの`.
スキル is passive info only.
No large separate character illustration, no なかまを変更 button.

## ちーむ
Three saved tabs; exactly four selected character cards numbered 1–4.
Right tabs exactly `ステータス / スキル / もちもの`.
No leader skill, team name, recommendation, empty plus cards, socket tab or edit pencil.

## もちもの
Categories `そうび / カケラ / その他`.
Inventory grid, selected item, 3 clickable shard slots, enhancement, equipped character, assignment change, total effects.

## Settings
Dim current screen + centered modal with X.
Language, BGM volume, SE volume, fullscreen PC only.
No master volume, text-size setting, separate back button or return-to-title.

## Localization
Plan for Japanese, English, Korean, Simplified Chinese.
Do not hard-code player-facing Japanese strings in gameplay scripts. Layouts must tolerate longer English strings.
