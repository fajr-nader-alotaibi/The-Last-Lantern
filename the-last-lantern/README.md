# The Last Lantern

A compact Godot 4.7 horror-exploration game-jam project. The game starts with an image-based main menu, a functional settings screen, a four-lantern forest level, and a timber-temple symbol puzzle with an ending.

## Run

Open this folder's `project.godot` in Godot 4.7 or newer and press **F5**. The project starts at the main menu. Press **F6** to run the currently open scene from the editor.

## Controls

| Key | Action |
| --- | --- |
| W A S D | Move relative to the camera |
| Q / E | Orbit the camera by the configured step |
| F | Light a lantern or use a nearby object |
| Shift | Run |
| Esc | Pause or go back |
| Mouse | Navigate menus; optional gameplay look is off by default |

## Menu and settings

The main menu uses `assets/ui/menu_forest_background.png` as a static 16:9 forest image, with native Godot labels, buttons, hover/focus treatments, a settings screen, and a quit confirmation. The screenshot in `assets/ui/main_menu_reference.png` is kept for visual reference only and is not shown as the interface.

Settings include editable movement/orbit/interaction bindings, camera behavior, display mode and supported window sizes, VSync, 3D anti-aliasing quality, Master/Music/SFX levels, UI scale, prompts, and English/Arabic localization with right-to-left layout. Key changes update Godot's live `InputMap`; duplicate bindings are rejected. Audio sliders update their buses as they move. **Apply** saves to `user://settings.cfg`; **Back** discards un-applied previews and restores the last saved settings.

The project includes forest and temple ambience, dirt and bridge footsteps, lantern ignition, branch creak, shrine wind, and whisper clips. Ambience and sound effects play on the existing Music and SFX buses. Keep the attribution in `assets/audio/README.md` if you share a build; the footstep clips require CC BY 3.0 attribution.

## Project structure

- `scenes/main_menu.tscn` and `scripts/ui/main_menu.gd` — image-backed menu and Play/Settings/Quit flow.
- `scenes/ui/settings_menu.tscn` and `scripts/ui/settings_menu.gd` — responsive settings categories and real interactive controls.
- `scripts/settings/settings_manager.gd` — one settings manager for ConfigFile persistence, input bindings, language, display, and audio.
- `scenes/forest.tscn` and `scripts/ui/forest.gd` — compact first level, lantern progression, lighting, ambience, and handoff to the temple.
- `scenes/temple.tscn` and `scripts/ui/temple.gd` — timber hall, four-symbol sequence puzzle, opening final door, and ending screen.
- `scripts/game_progress.gd` — keeps the order of lit lanterns between the two levels.
- `scenes/player.tscn` and `scripts/player/player_controller.gd` — third-person movement, camera orbit, character animations, and dirt/wood footsteps.
- `assets/character/explorer_rigged.glb` — the explorer with prototype idle, walk, and run animation clips.

The full play flow is implemented: the first forest lantern reveals the two side routes; Lanterns 2 and 3 can be lit in either order; their order determines the temple puzzle; Lantern 4 finishes Level 1 and opens Level 2; the correct four-symbol sequence opens the final double door and shows the ending.

## Prototype status

The forest is a compact connected blockout with a starting trail, short plank bridge, optional abandoned timber shelter, moonlit pond, rocky clearing, Torii gate, and a few imported pine/fern props. Lantern progression reveals the next paths and prevents lighting a later lamp too early. The temple is a lightweight timber interior assembled from Godot primitives so it stays enterable without waiting on an unfinished Meshy kit. It deliberately contains no religious statues or sacred props; the four puzzle marks are abstract symbols. This is a jam-ready prototype, so review scale, collision, and the final art in Godot before exporting.

See [`assets/models/README.md`](assets/models/README.md) for the reviewed model shortlist, licensing notes, and Meshy prompts.
