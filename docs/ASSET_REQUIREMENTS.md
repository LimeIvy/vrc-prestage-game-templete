# Asset Requirements

UI画像・アイコンを差し替え可能にするための配置ルールです。
画像はゲーム内で素材として利用する想定です。参考画像そのものは使用しません。

## 共通ルール

- 形式: 透過が必要なものは PNG。
- 基準解像度: 1920x1080。
- キャラクター、敵、装備、カケラ、アイコンは背景透過推奨。
- ファイル名は小文字スネークケースで統一。
- Godot側では、画像が存在しない場合は仮表示へフォールバックできるように実装します。

## フォルダ構成

```text
assets/
  backgrounds/
  characters/
  enemies/
  equipment/
  shards/
  items/
  icons/
  ui/
  gacha/
```

## 背景画像

| 用途 | ファイル名 | 置き場所 | 推奨サイズ |
|---|---|---|---|
| 通常フィールド背景 | `bg_field_day.png` | `assets/backgrounds/` | 1920x1080 |
| ガチャ背景 | `bg_gacha.png` | `assets/backgrounds/` | 1920x1080 |
| ガチャ結果背景 | `bg_gacha_result.png` | `assets/backgrounds/` | 1920x1080 |
| 帰還背景 | `bg_return.png` | `assets/backgrounds/` | 1920x1080 |

## キャラクター画像

| 表示名 | ID | ファイル名 | 置き場所 | 推奨サイズ |
|---|---|---|---|---|
| ひなた | `debug_ssr_fire` | `char_hinata.png` | `assets/characters/` | 512x512 |
| しずく | `debug_sr_water` | `char_shizuku.png` | `assets/characters/` | 512x512 |
| こはる | `debug_r_grass` | `char_koharu.png` | `assets/characters/` | 512x512 |
| まめ | `debug_n_none` | `char_mame.png` | `assets/characters/` | 512x512 |

### ガチャ表示用の追加候補

```text
assets/characters/char_suzu.png
assets/characters/char_touka.png
assets/characters/char_aoi.png
assets/characters/char_hoshino.png
```

## 敵画像

| 用途 | ファイル名 | 置き場所 | 推奨サイズ |
|---|---|---|---|
| 通常敵 ふわカケラ | `enemy_fuwa_kakera.png` | `assets/enemies/` | 768x768 |
| ボス まよいの大カケラ | `enemy_boss_mayoi_kakera.png` | `assets/enemies/` | 900x900 |

## 装備画像

| 表示名 | ID | ファイル名 | 置き場所 | 推奨サイズ |
|---|---|---|---|---|
| 星灯りのつえ | `debug_ssr_blade` | `equip_star_staff.png` | `assets/equipment/` | 512x512 |
| 水玉のベル | `debug_sr_blade` | `equip_water_bell.png` | `assets/equipment/` | 512x512 |
| 若葉のピン | `debug_r_blade` | `equip_leaf_pin.png` | `assets/equipment/` | 512x512 |
| ちいさな木刀 | `debug_n_blade` | `equip_wood_sword.png` | `assets/equipment/` | 512x512 |

### ガチャ表示用の追加候補

```text
assets/equipment/equip_cloth_ribbon.png
assets/equipment/equip_stone_charm.png
assets/equipment/equip_lantern.png
assets/equipment/equip_moon_robe.png
assets/equipment/equip_mushroom.png
assets/equipment/equip_bag.png
assets/equipment/equip_clover.png
assets/equipment/equip_potion.png
assets/equipment/equip_flower.png
```

## カケラ画像

| 表示名 | ID | ファイル名 | 置き場所 | 推奨サイズ |
|---|---|---|---|---|
| 赤いカケラ | `mock_shard_attack` | `shard_red.png` | `assets/shards/` | 256x256 |
| 青いカケラ | `mock_shard_speed` | `shard_blue.png` | `assets/shards/` | 256x256 |
| 緑のカケラ | `mock_shard_element` | `shard_green.png` | `assets/shards/` | 256x256 |
| 空ソケット | なし | `shard_empty_socket.png` | `assets/shards/` | 256x256 |
| ロック中ソケット | なし | `shard_locked_socket.png` | `assets/shards/` | 256x256 |

## 素材・通貨アイコン

| 用途 | ファイル名 | 置き場所 | 推奨サイズ |
|---|---|---|---|
| ひかり石 | `item_hikari_stone.png` | `assets/items/` | 128x128 |
| おやつ | `item_snack.png` | `assets/items/` | 128x128 |
| パーツ | `item_parts.png` | `assets/items/` | 128x128 |
| 星砂 | `item_star_sand.png` | `assets/items/` | 128x128 |
| おもいで | `item_memory.png` | `assets/items/` | 128x128 |

## UIアイコン

| 用途 | ファイル名 | 置き場所 | 推奨サイズ |
|---|---|---|---|
| 戦闘タブ | `icon_battle.png` | `assets/icons/` | 128x128 |
| なかまタブ | `icon_character.png` | `assets/icons/` | 128x128 |
| チームタブ | `icon_team.png` | `assets/icons/` | 128x128 |
| もちものタブ | `icon_equipment.png` | `assets/icons/` | 128x128 |
| であいタブ | `icon_gacha.png` | `assets/icons/` | 128x128 |
| きかんタブ | `icon_return.png` | `assets/icons/` | 128x128 |
| メニュー | `icon_menu.png` | `assets/icons/` | 128x128 |
| 設定 | `icon_settings.png` | `assets/icons/` | 128x128 |
| 閉じる | `icon_close.png` | `assets/icons/` | 128x128 |
| 火 | `icon_element_fire.png` | `assets/icons/` | 128x128 |
| 水 | `icon_element_water.png` | `assets/icons/` | 128x128 |
| 草 | `icon_element_grass.png` | `assets/icons/` | 128x128 |
| 無 | `icon_element_none.png` | `assets/icons/` | 128x128 |
| 攻撃力 | `icon_stat_attack.png` | `assets/icons/` | 128x128 |
| 攻撃速度 | `icon_stat_speed.png` | `assets/icons/` | 128x128 |
| クリティカル率 | `icon_stat_crit_rate.png` | `assets/icons/` | 128x128 |
| クリティカルダメージ | `icon_stat_crit_damage.png` | `assets/icons/` | 128x128 |
| 元素ダメージ | `icon_stat_element_damage.png` | `assets/icons/` | 128x128 |
| お気に入り | `icon_favorite.png` | `assets/icons/` | 128x128 |
| ロック | `icon_lock.png` | `assets/icons/` | 128x128 |
| 入れ替え | `icon_swap.png` | `assets/icons/` | 128x128 |
| レベルアップ | `icon_level_up.png` | `assets/icons/` | 128x128 |

## UI装飾画像

| 用途 | ファイル名 | 置き場所 | 推奨サイズ |
|---|---|---|---|
| SSRバッジ | `badge_ssr.png` | `assets/ui/` | 160x80 |
| SRバッジ | `badge_sr.png` | `assets/ui/` | 160x80 |
| Rバッジ | `badge_r.png` | `assets/ui/` | 160x80 |
| Nバッジ | `badge_n.png` | `assets/ui/` | 160x80 |
| NEWラベル | `label_new.png` | `assets/ui/` | 180x90 |
| 星ON | `star_on.png` | `assets/ui/` | 96x96 |
| 星OFF | `star_off.png` | `assets/ui/` | 96x96 |
| 矢印左 | `arrow_left.png` | `assets/ui/` | 128x128 |
| 矢印右 | `arrow_right.png` | `assets/ui/` | 128x128 |

## 最小セット

最初にUIへ組み込むための最小セットです。

```text
assets/backgrounds/bg_field_day.png
assets/backgrounds/bg_gacha.png
assets/backgrounds/bg_gacha_result.png
assets/backgrounds/bg_return.png

assets/characters/char_hinata.png
assets/characters/char_shizuku.png
assets/characters/char_koharu.png
assets/characters/char_mame.png

assets/enemies/enemy_fuwa_kakera.png
assets/enemies/enemy_boss_mayoi_kakera.png

assets/equipment/equip_star_staff.png
assets/equipment/equip_water_bell.png
assets/equipment/equip_leaf_pin.png
assets/equipment/equip_wood_sword.png

assets/shards/shard_red.png
assets/shards/shard_blue.png
assets/shards/shard_green.png
assets/shards/shard_empty_socket.png

assets/items/item_hikari_stone.png
assets/items/item_snack.png
assets/items/item_parts.png

assets/icons/icon_battle.png
assets/icons/icon_character.png
assets/icons/icon_team.png
assets/icons/icon_equipment.png
assets/icons/icon_gacha.png
assets/icons/icon_return.png
assets/icons/icon_menu.png
assets/icons/icon_settings.png
assets/icons/icon_element_fire.png
assets/icons/icon_element_water.png
assets/icons/icon_element_grass.png
assets/icons/icon_element_none.png
```
