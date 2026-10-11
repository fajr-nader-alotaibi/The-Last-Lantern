# The Last Lantern

A compact Godot 4.7 horror-exploration game-jam project. The game starts with an image-based main menu, a functional settings screen, and a playable forest opening with an interactable lantern.

## Run

Open this folder's `project.godot` in Godot 4.7 or newer and press **F5**. The project starts at the main menu. Press **F6** to run the currently open scene from the editor.

## Controls

| Key | Action |
| --- | --- |
| W A S D | Move relative to the camera |
| Q / E | Orbit the camera by the configured step |
| F | Light a lantern or use a nearby object |
| Esc | Pause or go back |
| Mouse | Navigate menus; optional gameplay look is off by default |

## Menu and settings

The main menu uses `assets/ui/menu_forest_background.png` as a static 16:9 forest image, with native Godot labels, buttons, hover/focus treatments, a settings screen, and a quit confirmation. The screenshot in `assets/ui/main_menu_reference.png` is kept for visual reference only and is not shown as the interface.

Settings include editable movement/orbit/interaction bindings, camera behavior, display mode and supported window sizes, VSync, 3D anti-aliasing quality, Master/Music/SFX levels, UI scale, prompts, and English/Arabic localization with right-to-left layout. Key changes update Godot's live `InputMap`; duplicate bindings are rejected. Audio sliders update their buses as they move. **Apply** saves to `user://settings.cfg`; **Back** discards un-applied previews and restores the last saved settings.

The project contains no music, ambience, or UI sound assets. The Audio screen includes a short generated preview tone; add the game's own ambience and UI audio later if desired.

## Project structure

- `scenes/main_menu.tscn` and `scripts/ui/main_menu.gd` — image-backed menu and Play/Settings/Quit flow.
- `scenes/ui/settings_menu.tscn` and `scripts/ui/settings_menu.gd` — responsive settings categories and real interactive controls.
- `scripts/settings/settings_manager.gd` — one settings manager for ConfigFile persistence, input bindings, language, display, and audio.
- `scenes/forest.tscn`, `scenes/player.tscn`, and `scripts/` — playable opening, third-person movement, camera orbit, pause menu, HUD, and lantern interaction.
- `assets/character/explorer.glb` — supplied explorer model.

The forest opening currently has one working lantern; the counter and progression are prepared for four, while the remaining locations and temple puzzle still need to be built.
