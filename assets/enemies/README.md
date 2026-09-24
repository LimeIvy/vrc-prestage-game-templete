# Enemy Visual Parts

Normal enemies are generated from a body plus smaller anchored transparent PNG parts.

Godot prototype and future Unity/VRChat builds should share the IDs and paths in:

`res://data/enemy_visual_catalog.json`

Required folders:

- `bodies/`
- `patterns/`
- `eyes/`
- `mouths/`
- `accessories/`

Bodies use the shared body canvas and provide anchor data in the catalog:

- `face_anchor` for eyes and mouth.
- `head_anchor` for head accessories.
- `pattern_area` for body-dependent pattern placement or masking.
- `eye_spacing` as the body default.

Eyes are authored as one eye per PNG. Runtime creates left and right eye nodes around `face_anchor`.
Mouths and accessories are authored as cropped transparent PNGs and positioned from the relevant anchor.
Patterns are body-dependent; prefer mask/shader composition over a universal full-canvas overlay as the system matures.

Color variants should not be exported as separate images. Use neutral source art and tint/shader color changes from the recipe palettes.
