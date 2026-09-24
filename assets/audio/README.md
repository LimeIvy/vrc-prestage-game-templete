# Audio Assets

Put BGM and SE files here.

Recommended layout:

- `bgm/`
- `se/`

Runtime entry point:

- `/root/AudioManager.play_bgm("res://assets/audio/bgm/xxx.ogg")`
- `/root/AudioManager.play_se("res://assets/audio/se/xxx.wav")`

The prototype creates `BGM` and `SE` audio buses at runtime and stores volume settings in:

`user://audio_settings.json`

Use neutral paths and IDs so the same asset list can be mapped to Unity/VRChat later.
